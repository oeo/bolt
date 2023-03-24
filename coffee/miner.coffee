config = require './config'

log 'Miner started'

mongoose = require 'mongoose'
await mongoose.connect config.storage.mongo

Wallet = require './lib/wallet'
Blockchain = require './models/blockchain'

# find blockchain
blockchain = await Blockchain.connect()

# create new wallet
wallet = new Wallet('privatekeyhere')
wallet.use(blockchain)

# mine
while 1
  if solved = await blockchain.mineBlock(wallet.address)
    log 'Mined a block', solved
    log 'Wallet balance:', await wallet.getBalance()
