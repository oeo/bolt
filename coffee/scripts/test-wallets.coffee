#!/usr/bin/env coffee
config = require './../config'

mongoose = require 'mongoose'
await mongoose.connect config.storage.mongo 

Transaction = require './../models/transaction'
Blockchain = require './../models/blockchain'

Wallet = require './../lib/wallet'

# connect or create chain 
blockchain = new Blockchain()
await blockchain.init()

# create some wallets
wallets = {
  doug: new Wallet('privatekeyhere')
  john: new Wallet('9dcc0ab7e6c07633c2dea51a12c1095fd10dc3dadddd2e9df2283d22deb73371')
}

wallets.doug.use(blockchain)
wallets.john.use(blockchain)

log await wallets.doug.getBalance()
log await wallets.john.getBalance()

#await blockchain.mineBlock(wallets.doug.address)

## add txns to mempool
await blockchain.addTransaction({
  from: wallets.doug.address,
  to: wallets.john.address,
  amount: 5,
  comment: 'here free' 
}, wallets.doug)

await blockchain.addTransaction({
  from: wallets.doug.address,
  to: wallets.john.address,
  amount: 1,
  fee: 0.5,
  comment: 'highest prio' 
}, wallets.doug)

