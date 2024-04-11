# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
config = require './../lib/globals'
module.exports = router = require('express').Router()

Wallet = require './../lib/wallet'
Block = require '../models/block'
Blockchain = require './../models/blockchain'

router.post "/wallets/create", ((req, res, next) ->
  w = new Wallet {
    seed: req.options.seed
    privateKey: req.options.privateKey
  }

  return res.json w.toJSON()
)

router.get "/wallets/:address/balance", ((req, res, next) ->
  # Retrieve the balance of a specific wallet address
  blockchain = new Blockchain()

  result = await blockchain.addressBalance(
    address,
    req.options.includeMempool
  )

  return res.json result
)

router.get "/wallets/:address/transactions", ((req, res, next) ->
  # Retrieve a list of transactions associated with a specific wallet address
)

router.get "/wallets/:address/utxos", ((req, res, next) ->
  # Retrieve the unspent transaction outputs (UTXOs) associated with a specific wallet address
)

router.post "/wallets/:address/sign", ((req, res, next) ->
  # Sign a transaction using the private key associated with a specific wallet address
)

router.get "/wallets/addresses", ((req, res, next) ->
  # Retrieve a list of all wallet addresses managed by the node
)

