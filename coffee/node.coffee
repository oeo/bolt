config = require './config'

mongoose = require 'mongoose'
await mongoose.connect config.storage.mongo 

Transaction = require './models/transaction'
Blockchain = require './models/blockchain'

Wallet = require './lib/wallet'
wallet = new Wallet()

log /wallet/, wallet
process.exit 0

blockchain = new Blockchain()
await blockchain.sync()
