const { log } = require('../utils/log');
const { merkleHash, merkleHashStr } = require('../utils/merkleHash');

const _ = require('lodash')

const { scrypt, scryptAsync } = require('@noble/hashes/scrypt')

class Block {
  constructor(transactions, previousHash = '', config = {}) {
    this.ctime = Math.round(new Date().getTime()/1000) 
    this.transactions = transactions || [];
    this.previousHash = previousHash;
    this.nonce = 0;
    this.difficulty = config.difficulty || config.initialDifficulty;
    this.comment = config.comment || null;
    this.merkleHash = merkleHashStr(this.transactions)
    this.hash = null;
  }

  async init() {
    return this;
  }

  renderBlock(includeHash = true) {
    let b = {
      ctime: this.ctime,
      transactions: this.transactions,
      previousHash: this.previousHash,
      nonce: this.nonce,
      difficulty: this.difficulty,
      comment: this.comment || undefined,
      merkleHash: this.merkleHash,
    }

    if (includeHash) {
      b.hash = this.hash
    }

    return b
  }

  async calculateHash(returnString = false) {
    const data = JSON.stringify(this.renderBlock(false))
    const hashBuf = await scryptAsync(data, '', { N: 1024, r: 8, p: 1, dkLen: 32 });

    if (returnString) {
      return Buffer.from(hashBuf).toString('hex')
    }

    return hashBuf
  }

  async mineBlock() {
    while (true) {
      this.hash = await this.calculateHash()

      let do_cont = false

      for (let x = 1; x <= this.difficulty; x++) {
        if (this.hash[x] !== 0) {
          this.nonce += 1;
          do_cont = true
          break
        }
      }

      if (do_cont) {
        continue
      }

      this.hash = await this.calculateHash(true) 
      break
    }

    return this.renderBlock(true)
  }

  getTransactionData() {
    let transactionData = [];

    for (const transaction of this.transactions) {
      transactionData.push({
        from: transaction.from,
        to: transaction.to,
        amount: transaction.amount,
      });
    }

    return transactionData;
  }

}

const createBlock = async (transactions, previousHash, config) => {
  const block = new Block(transactions, previousHash, config);
  return await block.init();
};

module.exports = {
  Block,
  createBlock,
};
