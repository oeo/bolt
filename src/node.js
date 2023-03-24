const config = require('./config')
const { log } = require('./utils/log')

const _ = require('lodash')

const { Block, createBlock } = require('./lib/block')
const { Blockchain } = require('./lib/blockchain')
const { Transaction } = require('./lib/transaction')
const { Wallet } = require('./lib/wallet')

// node
async function main() {
  let blockchain

  try {
    blockchain = await new Blockchain(config);
  } catch (error) {
    console.error('Error initializing the blockchain:', error);
  }

  const satoshi = new Wallet();
  const wallet1 = new Wallet();
  const wallet2 = new Wallet();

  log.debug(_.merge({ balance: await wallet1.getBalance(blockchain) }, _.pick(wallet1, ['publicKey', 'privateKey', 'address'])), 'Wallet 1');
  log.debug(_.merge({ balance: await wallet2.getBalance(blockchain) }, _.pick(wallet2, ['publicKey', 'privateKey', 'address'])), 'Wallet 2');

  log.debug('Wallet 1 starting mining', wallet1.address);
  await blockchain.mineBlock(wallet1.address);

  log.debug(_.merge({ balance: await wallet1.getBalance(blockchain) }, _.pick(wallet1, ['publicKey', 'privateKey', 'address'])), 'Wallet 1');
  log.debug(_.merge({ balance: await wallet2.getBalance(blockchain) }, _.pick(wallet2, ['publicKey', 'privateKey', 'address'])), 'Wallet 2');

  log.debug('Sending money from Wallet 1 to Wallet 2');

  let txn = new Transaction({
    from: wallet1.address,
    to: wallet2.address,
    amount: 13,
    fee: 0.025,
    memo: 'Loaning you money man',
  });

  wallet1.signTransaction(txn);

  blockchain.createTransaction(txn);
  await blockchain.mineBlock(satoshi.address);

  log.debug(_.merge({ balance: await wallet1.getBalance(blockchain) }, _.pick(wallet1, ['publicKey', 'privateKey', 'address'])), 'Wallet 1');
  log.debug(_.merge({ balance: await wallet2.getBalance(blockchain) }, _.pick(wallet2, ['publicKey', 'privateKey', 'address'])), 'Wallet 2');
}

main()
