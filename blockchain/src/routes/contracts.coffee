# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
config = require './../lib/globals'

module.exports = router = require('express').Router()

router.post "/contracts/deploy", ((req, res, next) ->
  # Deploy a new smart contract to the blockchain
)

router.get "/contracts/:contractAddress", ((req, res, next) ->
  # Retrieve information about a specific smart contract by its address
)

router.post "/contracts/:contractAddress/execute", ((req, res, next) ->
  # Execute a function of a smart contract
)

router.get "/contracts/:contractAddress/storage", ((req, res, next) ->
  # Retrieve the storage data of a smart contract
)

router.get "/contracts/:contractAddress/events", ((req, res, next) ->
  # Retrieve the emitted events of a smart contract
)
