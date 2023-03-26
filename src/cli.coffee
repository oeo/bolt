config = require './lib/globals'

commander = require 'commander'

Wallet = require './lib/wallet'
Block = require './models/block'
Blockchain = require './models/blockchain'

blockchain = new Blockchain()
await blockchain.sync()

commander
  .version('1.0.0')
  .description('Wallet CLI')

commander
  .command('create')
  .description('Create a new wallet')
  .option('-s, --seed [seed]', 'The seed phrase to generate wallet from')
  .option('-p, --privateKey [privateKey]', 'The private key to generate wallet from')
  .action (options) ->
    wallet = new Wallet(options.seed, options.privateKey)
    log wallet.toJSON()
    exit 0

commander
  .command('balance <address>')
  .description('Get the balance of a wallet')
  .option('--include-mempool', 'Include mempool transactions in the balance calculation')
  .action (address, options) ->
    result = await blockchain.addressBalance(
      address,
      options.includeMempool
    )

    log result
    exit 0

commander.parse process.argv

if process.argv.length <= 2
  commander.outputHelp()
