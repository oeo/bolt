config = require './config'

mongoose = require 'mongoose'

log 'Connecting to ' + JSON.stringify(config.storage.mongo)
await mongoose.connect config.storage.mongo 

Transaction = require './models/transaction'

Blockchain = require './models/blockchain'
blockchain = await Blockchain.findOne default:true

Wallet = require './lib/wallet'

if !blockchain
  log 'Creating new blockchain'

  blockchain = new Blockchain()
  blockchain.save()
else
  log 'Blockchain loaded'
  log blockchain.toJSON()
  await blockchain.createGenesisBlock()

## testing
wallets = {
  doug: new Wallet('0429df98f3944e2f85999be274620f3cff886b83172187f276c1ae7361bb46d0')
  john: new Wallet('9dcc0ab7e6c07633c2dea51a12c1095fd10dc3dadddd2e9df2283d22deb73371')
}

await blockchain.mineBlock(wallets.doug.address)

balance = await blockchain.getBalance(wallets.doug.address)

## add txns to mempool
await blockchain.addTransaction({
  from: wallets.doug.address,
  to: wallets.john.address,
  amount: 5,
  comment: 'here free' 
},wallets.doug)

await blockchain.addTransaction({
  from: wallets.doug.address,
  to: wallets.john.address,
  amount: 1,
  fee: 0.5,
  comment: 'highest prio' 
},wallets.doug)

# mine the txns
await blockchain.mineBlock(wallets.john.address)

