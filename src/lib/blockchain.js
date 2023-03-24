const config = require(__dirname + '/../config')
const { log } = require('../utils/log')
const { redis } = require('../utils/redis')

const { merkleHash, merkleHashStr } = require('../utils/merkleHash');

const _ = require('lodash')

const { Wallet } = require('./wallet')
const { Block, createBlock } = require('./block')
const { Transaction } = require('./transaction')

class Blockchain {

  constructor(config) {
    this.config = config;
    this.difficulty = config.difficulty || config.initialDifficulty;
    this.miningReward = config.miningReward || config.initialReward;

    this.mempool = [];
  
    return (async () => {
      await this.init();
      return this
    })()
  }

  async init() {
    return new Promise(async (resolve, reject) => {
      try {
        const chainLength = await this.getChainLength()
        
        if (chainLength > 0) {
          const lastBlock = await this.getLatestBlock()
          this.difficulty = lastBlock.difficulty

          let start = new Date().getTime()
          log.trace('Start validating ' + chainLength + ' blocks')

          try {
            let validChain = await this.isChainValid()
            log.trace('Finished validated chain in ' + (new Date().getTime() - start) + 'ms')

          } catch (e) {
            log.error(e)
            throw(e)
          }

          log.warn(lastBlock, 'lastBlock')

        } else {
          const genesis = await this.createGenesisBlock()
          await this.addBlock(genesis)

          log.info(genesis, 'Genesis block added')
        }
        
        resolve()
      } catch (error) {
        reject(error)
      }
    })
  }
  
  async createGenesisBlock() {
    let genesis = await createBlock(
      this.config.genesisData.transactions,
      this.config.genesisData.previousHash,
      this.config.genesisData
    )

    genesis.hash = await genesis.calculateHash(true)
    genesis.height = 0

    return genesis
  }

  async mineBlock(miningRewardAddress = null) {
    let fees = 0;
    for (const transaction of this.mempool) {
      if (transaction.fee) {
        fees += transaction.fee;
      }
    }
  
    // Create reward transaction
    const rewardTransaction = new Transaction({
      from: null,
      to: miningRewardAddress,
      amount: this.miningReward + fees,
      fee: 0,
      memo: 'BLOCK_MINING_REWARD'
    });
  
    // Sort pending transactions based on their fees in descending order
    const sortedPendingTransactions = this.mempool.sort((a, b) => b.fee - a.fee);
  
    // Initialize block transactions and size
    const blockTransactions = [];
    let blockSize = JSON.stringify(rewardTransaction).length;
  
    // Add transactions to the block until maxBlockSize or maxTransactionsPerBlock is reached
    for (const transaction of sortedPendingTransactions) {
      const transactionSize = JSON.stringify(transaction).length;
  
      if (blockSize + transactionSize <= this.config.maxBlockSize && blockTransactions.length < this.config.maxTransactionsPerBlock) {
        blockTransactions.push(transaction);
        blockSize += transactionSize;
      } else {
        break;
      }
    }
  
    // Add reward transaction to the block
    blockTransactions.push(rewardTransaction);

    // Adjust the difficulty before mining the new block
    await this.adjustDifficulty()
  
    const block = await createBlock(blockTransactions, (await this.getLatestBlock()).hash, {
      difficulty: this.difficulty,
    })

    block.height = (await this.getLatestBlock()).height + 1

    await block.mineBlock()
    await this.addBlock(block)

    log.info(block, 'Block mined by ' + miningRewardAddress);
  
    // Remove the mined transactions from the mempool 
    this.mempool = this.mempool.filter(tx => !blockTransactions.includes(tx));

    log.debug('Finished mineBlock: ' + await this.getChainLength() + ' ' + block.hash);
  }

  async addBlock(newBlock) {
    console.log('Adding block:', newBlock);
  
    const chainLength = await this.getChainLength();
  
    if (chainLength > 0) {
      const latestBlock = await this.getLatestBlock();

      if (newBlock.height !== latestBlock.height + 1) {
        throw new Error('Invalid block height');
      }
      if (newBlock.previousHash !== latestBlock.hash) {
        throw new Error('Invalid previous hash');
      }
      if (!await this.isChainValid([latestBlock,newBlock])){
        throw new Error('Adding block failed')
      }

    } else {
      // This is the genesis block, so there's no need to check the previous block properties
      if (newBlock.height !== 0) {
        throw new Error('Invalid genesis block height');
      }
      if (newBlock.previousHash !== '0000000000000000000000000000000000000000000000000000000000000000') {
        throw new Error('Invalid genesis block previous hash');
      }
    }

    await redis.rpush('chain', JSON.stringify(newBlock));
  }
  
  createTransaction(transaction) {
    transaction.fee = Number(transaction.fee) || config.minFee

    if (!transaction.isValid()) {
      throw new Error('Transaction failed. Signature is invalid')
    }

    if (transaction.fee < config.minFee) {
      throw new Error(`Transaction failed. Fee is below minFee: ${config.minFee}`);
    }

    if (this.getBalanceOfAddress(transaction.from) < transaction.amount + transaction.fee) {
      throw new Error(`Transaction failed. ${transaction.from} has insufficient funds.`);
    }

    this.mempool.push(transaction)
  }

  async getBalanceOfAddress(address) {
    let balance = 0
    let short = null
    const chainLength = await this.getChainLength();

    if (!address.startsWith('b_')){
      log.debug(address,'Address')
      let w = Wallet.fromPublicKey(address)
      short = w.address 
    }

    let valid = _.compact([
      address,
      short,
    ])

    for (let i = 0; i < chainLength; i++) {
      const block = await this.getBlockByIndex(i);

      if (block && block.transactions && block.transactions.length) {
        for (const item of block.transactions) {
          if (valid.includes(item.from)) {
            balance -= item.amount + item.fee
          }
          if (valid.includes(item.to)) {
            balance += item.amount
          }
        }
      }
    }
  
    return balance
  }

  async isChainValid(blocksToValidate = null) {
    if (!blocksToValidate) {
      const chainLength = await this.getChainLength();
  
      for (let i = 1; i < chainLength; i++) {
        const currentBlock = await this.getBlockByIndex(i);
        const previousBlock = await this.getBlockByIndex(i - 1);
  
        if (!await this.validateBlockPair(currentBlock, previousBlock)) {
          return false;
        }
      }
    } else {
      for (let i = 1; i < blocksToValidate.length; i++) {
        const currentBlock = blocksToValidate[i];
        const previousBlock = blocksToValidate[i - 1];
  
        if (!await this.validateBlockPair(currentBlock, previousBlock)) {
          return false;
        }
      }
    }
  
    return true;
  }

  async validateBlockPair(currentBlock, previousBlock) {
    if (currentBlock.hash !== await currentBlock.calculateHash(true)) {
      log.error(new Error('Hash provided does not match calculated hash'));
      return false;
    }
  
    if (currentBlock.previousHash !== previousBlock.hash) {
      log.error(new Error('One or more blocks have hashes that do not link'));
      return false;
    }
  
    // Validate each transaction in the block
    for (const transaction of currentBlock.transactions) {
      if (!transaction.isValid()) {
        log.error(new Error('Invalid transaction found in a block'));
        return false;
      }
    }
  
    // Validate the Merkle hash
    const calculatedMerkleHash = merkleHashStr(currentBlock.transactions);
  
    if (currentBlock.merkleHash !== calculatedMerkleHash) {
      log.error(new Error('Invalid Merkle hash found in a block'));
      return false;
    }
  
    return true;
  }

  async getChainLength() {
    return await redis.llen('chain')
  }

  async getBlockByIndex(index) {
    const blockData = await redis.lindex('chain', index)
    return Block.fromJSON(JSON.parse(blockData))
  }

  async getLatestBlock() {
    const chainLength = await this.getChainLength();
    return await this.getBlockByIndex(chainLength - 1);
  }

  async adjustDifficulty() {
    const chainLength = await this.getChainLength();

    if ((chainLength - 1) % this.config.difficultyAdjustmentInterval === 0 && chainLength > 1) {
      const startIndex = chainLength - 1 - this.config.difficultyAdjustmentInterval;
      const startTime = (await this.getBlockByIndex(startIndex)).ctime;
      const endTime = (await this.getBlockByIndex(chainLength - 1)).ctime;
  
      const timeElapsed = endTime - startTime;
      const targetTime = this.config.difficultyAdjustmentInterval * this.config.blockInterval;
  
      // Adjust difficulty based on time elapsed relative to the target time
      if (timeElapsed < targetTime * 0.9) {
        this.difficulty++;
        log.warn('Increasing block difficulty: ' + this.difficulty)
      } else if (timeElapsed > targetTime * 1.1) {
        this.difficulty = Math.max(this.difficulty - 1, this.config.initialDifficulty);
        log.warn('Adjusting block difficulty: ' + this.difficulty)
      }
    }
  }

}

module.exports = {
  Blockchain,
}
