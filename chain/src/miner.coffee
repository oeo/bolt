config = require './lib/globals'

_ora = (await import('ora')).default
ora = _ora()

{time} = require './lib/helpers'

Wallet = require './lib/wallet'
Block = require './models/block'
Blockchain = require './models/blockchain'

ora.spinner = 'layer'
ora.start('Syncing blockchain')

# connect to chain
blockchain = new Blockchain()
await blockchain.sync()

ora.succeed('Finished syncing blockchain data')

ora.start('Creating wallets from ./data/test-wallets.json') 

# create wallets
wallets = {}

walletJSON = require('fs').readFileSync('./data/test-wallets.json')
walletJSON = JSON.parse(walletJSON)

for item in walletJSON
  wallets[item.name] = new Wallet(item.mnemonic)
  wallets[item.name].use(blockchain)

ora.succeed('Finished loading wallets')

# mine
while 1
  wallet = _.first(_.shuffle(_.values(wallets)))
  nextBlock = await blockchain.nextBlock(wallet)

  start = time()
  ora.start 'Mining block #' + nextBlock._id + ' (difficulty: ' + nextBlock.difficulty + ')'

  if solvedHash = await nextBlock.mine()

    lastBlock = await Block
      .findOne({blockchain: nextBlock.blockchain})
      .sort({_id:-1})
      .limit(1)

    if lastBlock?._id and lastBlock._id + 1 isnt nextBlock._id
      continue

    nextBlock.hash = solvedHash

    try
      if await nextBlock.isValid()
        if success = await nextBlock.save()
          blockReward = _.find(success.transactions,{comment:'block_reward',from:null})
          ora.succeed 'Mined block #' + nextBlock._id + ' (difficulty: ' + success.difficulty + ')' + ' (' + (time() - start) + 's)' 
          if blockReward then log "> #{JSON.stringify(_.pick(blockReward,['amount','to']))}".grey

