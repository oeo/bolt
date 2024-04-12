config = require './../lib/globals'

{ time } = require './../lib/helpers'

Wallet = require './../lib/wallet'

Block = require './../models/block'
Blockchain = require './../models/blockchain'
{ Transaction } = require './../models/transaction'

# connect to chain
L 'syncing chain data'

blockchain = new Blockchain()
await blockchain.sync()

# load wallets
wallets = {}

walletJSON = require('fs').readFileSync('./../data/test-wallets.json')
walletJSON = JSON.parse(walletJSON)

for item in walletJSON
  # wallets[item.name] = new Wallet({ seed: item.mnemonic })
  wallets[item.name] = new Wallet({ privateKey: item.privateKey })
  wallets[item.name].use(blockchain)

L wallets
L "loaded #{_.size(wallets)} wallets to use for this mining session"

# mine blocks
while 1
  wallet = _.first(_.shuffle(_.values(wallets)))

  nextBlock = await blockchain.nextBlock(wallet)

  start = time()

  L """
    mining block ##{nextBlock._id} (difficulty=#{nextBlock.difficulty} algo=#{config.algo})
  """

  if solvedHash = await nextBlock.mine()
    lastBlock = await Block
      .findOne({ blockchain: nextBlock.blockchain })
      .sort({ _id: -1 })
      .limit 1

    if lastBlock?._id and lastBlock._id + 1 isnt nextBlock._id
      continue

    nextBlock.hash = solvedHash

    try
      await nextBlock.tryValidate()
    catch e
      log e
      continue

    try
      success = await nextBlock.save()
    catch e
      log e
      continue

    L.success """
      solved block ##{nextBlock._id} (nonce=#{success.nonce} elapsed=#{time() - start}s)
    """

    blockReward = _.find(success.transactions, {
      comment: 'block_reward',
    })

    if blockReward
      L.success """
          reward for ##{nextBlock._id} sent to #{blockReward.to} (#{blockReward.amount} bolt)
      """

