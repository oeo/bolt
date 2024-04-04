# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
config = require './../lib/globals'

module.exports = router = require('express').Router()

router.post "/transactions/send", ((req, res, next) ->
  # Submit a new transaction to the blockchain
)

router.get "/transactions/:txHash", ((req, res, next) ->
  # Retrieve a specific transaction by its hash
)

router.get "/transactions/block/:blockHash", ((req, res, next) ->
  # Retrieve all transactions included in a specific block by its hash
)

router.get "/transactions/address/:address", ((req, res, next) ->
  # Retrieve all transactions associated with a specific address
)

router.get "/transactions/pending", ((req, res, next) ->
  # Retrieve a list of pending transactions that have not yet been included in a block
)

router.get "/transactions/latest", ((req, res, next) ->
  # Retrieve the latest confirmed transactions
)

