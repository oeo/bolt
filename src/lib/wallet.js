const EC = require('elliptic').ec;
const crypto = require('crypto');

const ec = new EC('secp256k1');

class Wallet {
  constructor() {
    this.keyPair = ec.genKeyPair();

    this.publicKey = this.keyPair.getPublic('hex');
    this.privateKey = this.keyPair.getPrivate('hex');

    this.address = this.createAddress();
  }

  createAddress() {
    const publicKeyHash = crypto
      .createHash('sha256')
      .update(Buffer.from(this.publicKey, 'hex'))
      .digest();

    const address = crypto
      .createHash('ripemd160')
      .update(publicKeyHash)
      .digest('hex');

    return `b_${address}`;
  }

  signTransaction(transaction) {
    if (transaction.from !== this.address) {
      throw new Error('You cannot sign transactions for other wallets');
    }
  
    const hash = transaction.calculateHash();
    const sig = this.keyPair.sign(hash, 'hex');
    transaction.signature = sig.toDER('hex');
    
    // Add the public key to the transaction object
    transaction.publicKey = this.publicKey;
  
    return transaction;
  }

  static fromPrivateKey(privateKey) {
    const keyPair = ec.keyFromPrivate(privateKey, 'hex');
    const wallet = new Wallet();

    wallet.keyPair = keyPair;
    wallet.privateKey = privateKey;
    wallet.publicKey = keyPair.getPublic().encode('hex');
    wallet.address = wallet.createAddress();

    return wallet;
  }

  static fromPublicKey(publicKey) {
    const keyPair = ec.keyFromPublic(publicKey, 'hex');
    const wallet = new Wallet();

    wallet.keyPair = keyPair;
    wallet.publicKey = publicKey;
    wallet.address = wallet.createAddress();

    return wallet;
  }

  getBalance(blockchain) {
    let balance = 0;

    for (const block of blockchain.chain) {
      for (const transaction of block.transactions) {
        if (transaction.from === this.address) {
          balance -= transaction.amount + transaction.fee;
        }

        if (transaction.to === this.address) {
          balance += transaction.amount;
        }
      }
    }

    return balance;
  }
}

module.exports = { Wallet };
