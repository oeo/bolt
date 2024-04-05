# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
config = require './../lib/globals'
module.exports = router = require('express').Router()

router.get "/stats/transactions/count", ((req, res, next) ->
  # Retrieve the total number of transactions in the blockchain
)

router.get "/stats/transactions/volume", ((req, res, next) ->
  # Retrieve the total volume of transactions in the blockchain
)

router.get "/stats/addresses/count", ((req, res, next) ->
  # Retrieve the total number of unique addresses in the blockchain
)

router.get "/stats/blocks/count", ((req, res, next) ->
  # Retrieve the total number of blocks in the blockchain
)

router.get "/stats/blocks/time", ((req, res, next) ->
  # Retrieve the average block time of the blockchain
)

router.get "/stats/network/hashrate", ((req, res, next) ->
  # Retrieve the estimated network hashrate
)
