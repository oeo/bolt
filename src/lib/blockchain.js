const config = require(__dirname + '/../config')
const { log } = require('../utils/log')

const _ = require('lodash')

const { Wallet } = require('./wallet')
const { Block, createBlock } = require('./block')
const { Transaction } = require('./transaction')

class Blockchain {
  constructor(config) {
    this.config = config;
    this.chain = [];
    this.difficulty = config.difficulty || config.initialDifficulty;
    this.pendingTransactions = [];
    this.miningReward = config.miningReward || config.initialReward;
    this.miningInProgress = false
    this.init();
  }

  async init() {
    this.chain = [await this.createGenesisBlock()]
  }

  async createGenesisBlock() {
    let genesis = await createBlock(
      this.config.genesisData.transactions,
      this.config.genesisData.previousHash,
      this.config.genesisData
    )

    genesis.hash = await genesis.calculateHash(true)

    return genesis
  }

  getLatestBlock() {
    return this.chain[this.chain.length - 1]
  }

  async minePendingTransactions(miningRewardAddress = null) {
    if (this.miningInProgress) {
      return
    }

    this.miningInProgress = true

    let fees = 0;
    for (const transaction of this.pendingTransactions) {
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
    const sortedPendingTransactions = this.pendingTransactions.sort((a, b) => b.fee - a.fee);
  
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
  
    const block = await createBlock(blockTransactions, this.getLatestBlock().hash, this.config);
    await block.mineBlock(this.difficulty);
  
    log.info(block, 'Block mined by ' + miningRewardAddress);
    this.addBlock(block)
  
    // Remove mined transactions from the pending transactions (mempool)
    this.pendingTransactions = this.pendingTransactions.filter(tx => !blockTransactions.includes(tx));

    this.miningInProgress = false
    log.debug('Finished minePendingTransactions: ' + this.chain.length + ' ' + block.hash);
  }

  addBlock(blockObj) {
    log.info(blockObj,'addBlock')

    if (!this.isChainValid([_.last(this.chain),blockObj])){
      throw new Error('Adding block failed')
    }

    this.chain.push(blockObj)
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

    this.pendingTransactions.push(transaction)
  }

  getBalanceOfAddress(address) {
    let balance = 0
    let short = null

    if (!address.startsWith('b_')){
      log.debug(address,'Address')
      let w = Wallet.fromPublicKey(address)
      short = w.address 
    }

    let valid = _.compact([
      address,
      short,
    ])

    for (const block of this.chain) {
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

  async isChainValid() {
    for (let i = 1; i < this.chain.length; i++) {
      const currentBlock = this.chain[i];
      const previousBlock = this.chain[i - 1];
  
      if (currentBlock.hash !== await currentBlock.calculateHash(true)) {
        log.error(new Error('Hash provided does not match calculated hash'))
        return false;
      }
  
      if (currentBlock.previousHash !== previousBlock.hash) {
        log.error(new Error('One or more blocks have hashes that do not link'))
        return false;
      }
  
      // Validate each transaction in the block
      for (const transaction of currentBlock.transactions) {
        if (!transaction.isValid()) {
          log.error(new Error('Invalid transaction found in a block'))
          return false;
        }
      }
    }
  
    return true;
  }
  
  getChainData() {
    let chainData = []

    for (const block of this.chain) {
      chainData.push({
        hash: block.hash,
        previousHash: block.previousHash,
        transactions: block.getTransactionData()
      })
    }

    return chainData
  }
}

module.exports = {
  Blockchain,
}
