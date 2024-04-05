# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
config = require './../lib/globals'
module.exports = router = require('express').Router()

router.get "/network/peers", ((req, res, next) ->
  # Retrieve a list of connected peer nodes in the network
)

router.post "/network/peers/connect", ((req, res, next) ->
  # Connect to a new peer node
)

router.post "/network/peers/disconnect", ((req, res, next) ->
  # Disconnect from a connected peer node
)

router.get "/network/status", ((req, res, next) ->
  # Retrieve the current status of the node's network connection
)

router.post "/network/broadcast-transaction", ((req, res, next) ->
  # Broadcast a transaction to the network
)

router.post "/network/broadcast-block", ((req, res, next) ->
  # Broadcast a mined block to the network
)

