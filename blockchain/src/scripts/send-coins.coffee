config = require './../lib/globals'

{ time } = require './../lib/helpers'

Wallet = require './../lib/wallet'
Block = require './../models/block'
Blockchain = require './../models/blockchain'

{ Transaction } = require './../models/transaction'

blockchain = new Blockchain()
await blockchain.sync()

# load wallets
wallets = {}

walletJSON = require('fs').readFileSync('./../data/test-wallets.json')
walletJSON = JSON.parse(walletJSON)

for item in walletJSON
  wallets[item.name] = new Wallet({ seed: item.mnemonic })
  wallets[item.name].use(blockchain)

L "loaded #{_.size(wallets)} wallets to use for this mining session"

for name, wallet of wallets
  balance = await wallet.getBalance(true)
  L "wallet balance", name, wallet.address, balance

doug = wallets.doug
james = wallets.james

txn = new Transaction {
  from: doug.address
  to: james.address
  amount: 0.25
  comment: 'here you go bro, 0.25'
  publicKey: doug.publicKey
}

doug.signTransaction(txn)

log txn
log /txn/, txn

try
  await txn.tryValidate()
catch e
  log e

exit 0

