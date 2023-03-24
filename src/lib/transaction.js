const config = require(__dirname + '/../config');
const { log } = require('../utils/log');

const { Wallet } = require('./wallet');

const EC = require('elliptic').ec;
const ec = new EC('secp256k1');
const SHA256 = require('crypto-js/sha256');

class Transaction {

  constructor(transactionConfig) {
    this.from = transactionConfig.from;
    this.to = transactionConfig.to;
    this.amount = transactionConfig.amount;
    this.publicKey = transactionConfig.publicKey;

    this.fee = Number(transactionConfig.fee || config.minFee);

    if (this.from === null) {
      this.fee = 0;
    }

    // Enforce memo as a string-only with a maximum length of 255 characters
    this.memo = config.memo || null

    if (this.memo && typeof this.memo === 'string') {
      this.memo = this.memo.substr(0, config.maxTransactionMemoSize)
    } else {
      this.memo = null
    }

    this.memo = transactionConfig.memo || null;

    if (this.memo.length > config.maxMemoLength) {
      this.memo = this.memo.substr(0, config.maxMemoLength - 1);
    }

    if (this.from !== null && this.fee < config.minFee) {
      throw new Error(`Transaction creation failed. Fee is below minFee: ${config.minFee}`);
    }
  }

  static fromJSON(serializedTransaction) {
    const transactionConfig = {
      from: serializedTransaction.from,
      to: serializedTransaction.to,
      amount: serializedTransaction.amount,
      publicKey: serializedTransaction.publicKey,
      fee: serializedTransaction.fee,
      memo: serializedTransaction.memo,
    };

    const transaction = new Transaction(transactionConfig);
    transaction.signature = serializedTransaction.signature;
    return transaction;
  }

  calculateHash() {
    return SHA256(this.from + this.to + this.amount + this.fee + this.memo).toString();
  }

  isValid() {
    if (this.from === null) return true;

    if (!this.signature || this.signature.length === 0) {
      throw new Error('No signature in this transaction');
    }

    const keyPair = ec.keyFromPublic(this.publicKey, 'hex');

    if (!keyPair) {
      throw new Error('Invalid public key format');
    }

    return keyPair.verify(this.calculateHash(), this.signature);
  }
}

module.exports = {
  Transaction,
};
