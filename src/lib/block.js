const { config } = require('./../config');

const { log } = require('../utils/log');
const { merkleHash, merkleHashStr } = require('../utils/merkleHash');

const _ = require('lodash')

const { scrypt, scryptAsync } = require('@noble/hashes/scrypt')

const { Transaction } = require('./transaction')

class Block {

  constructor(transactions, previousHash = '', opt = {}) {
    this.ctime = opt.ctime || Math.round(new Date().getTime()/1000) 
    this.transactions = transactions || opt.transactions || [];
    this.previousHash = previousHash || opt.previousHash || null;
    this.nonce = opt.nonce || 0;
    this.difficulty = opt.difficulty || config.initialDifficulty;
    this.comment = opt.comment || null;
    this.merkleHash = opt.merkleHash || merkleHashStr(this.transactions)
    this.hash = opt.hash || null;
    this.height = opt.height || 0;
  }

  static fromJSON(serializedBlock) {
    serializedBlock.transactions = _.map(serializedBlock.transactions,(t) => {
      return Transaction.fromJSON(t)
    })

    return new Block(
      serializedBlock.transactions,
      serializedBlock.previousHash,
      {
        ctime: serializedBlock.ctime,
        nonce: serializedBlock.nonce,
        difficulty: serializedBlock.difficulty,
        comment: serializedBlock.comment,
        merkleHash: serializedBlock.merkleHash,
        hash: serializedBlock.hash,
        height: serializedBlock.height,
      }
    );
  }

  async init() {
    return this
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

    b.height = this.height

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

  // returns difficulty if valid, throws if hash mismatch
  async verifyWork() {
    let buff = await this.calculateHash()
    console.log(/buff/,buff)
  }

}

const createBlock = async (transactions, previousHash, opt = {}) => {
  const block = new Block(transactions, previousHash, opt);
  return await block.init();
};

module.exports = {
  Block,
  createBlock,
};
