config = require __dirname + '/globals'

Wallet = require './wallet'
Block = require '../models/block'
Blockchain = require '../models/blockchain'

module.exports.register = (commander) ->

  # dict
  commands = {
    chain: commander.command('chain')
    wallet: commander.command('wallet')
    config: commander.command('config')
  }

  # blockchain 
  commands.chain 
    .command('info')
    .description('get info about the blockchain')
    .action () ->
      result = await Blockchain.findOne _id:config.version
      log result 
      exit 0

  commands.chain 
    .command('block <height>')
    .description('get a block at a specific height')
    .action (height) ->
      result = await Block.findOne({
        blockchain: config.version
        _id: +height 
      })

      log result 
      exit 0

  # wallet
  commands.wallet 
    .command('create')
    .description('create a new wallet')
    .option('-s, --seed [seed]', 'the seed phrase to generate wallet from')
    .option('-p, --privateKey [privateKey]', 'the private key to generate wallet from')
    .action (options) ->
      wallet = new Wallet(options.seed, options.privateKey)
      log wallet.toJSON()
      exit 0

  commands.wallet 
    .command('balance <address>')
    .description('get the balance of a wallet')
    .option('--include-mempool', 'include mempool transactions in the balance calculation')
    .action (address, options) ->
      result = await blockchain.addressBalance(
        address,
        options.includeMempool
      )

      log result
      exit 0

  # config
  commands.config 
    .description('print configuration')
    .action ->
      log config 
      exit 0