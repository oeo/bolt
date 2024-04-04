# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
config = require './../../lib/globals'

module.exports = router = require('express').Router()

router.post "/mining/start", ((req, res, next) ->
  # Start the mining process on the node
)

router.post "/mining/stop", ((req, res, next) ->
  # Stop the mining process on the node
)

router.get "/mining/status", ((req, res, next) ->
  # Retrieve the current mining status of the node
)

router.get "/mining/block-template", ((req, res, next) ->
  # Retrieve the current block template for mining
)

router.post "/mining/submit-block", ((req, res, next) ->
  # Submit a mined block to the network
)

router.get "/mining/hashrate", ((req, res, next) ->
  # Retrieve the current mining hashrate of the node
)

