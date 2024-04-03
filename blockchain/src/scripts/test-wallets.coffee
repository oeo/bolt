#!/usr/bin/env coffee
config = require './../config'

mongoose = require 'mongoose'
await mongoose.connect config.storage.mongo 

Transaction = require './../models/transaction'
Blockchain = require './../models/blockchain'

Wallet = require './../lib/wallet'

blockchain = new Blockchain()
await blockchain.sync()

walletJSON = require('fs').readFileSync('./../data/test-wallets.json')
walletJSON = JSON.parse(walletJSON)

wallets = {}

for item in walletJSON
  wallets[item.name] = new Wallet({ seed: item.mnemonic })
  wallets[item.name].use(blockchain)

log 'Created wallets', _.keys(wallets)

log 'Mining a block using wallet "taky"'
await blockchain.mineBlock(wallets.taky.address)

## add txns to mempool
###
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
###
