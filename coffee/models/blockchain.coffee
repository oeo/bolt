config = require './../config'

mongoose = require 'mongoose'

Block = require './block'
{Transaction,TransactionSchema} = require './transaction'

P2P = require './../lib/p2p'

{
  time,
  sha256,
  indentedJSON,
  isObject,
} = require './../lib/helpers'

BlockchainSchema = new mongoose.Schema({

  _id: {
    type: String
    required: true
    default: config.version
  }

  default: {
    type: Boolean
    default: false 
  }

  miningReward: {
    type: Number
    default: config.initialReward
  }

  difficulty: {
    type: Number
    default: config.initialDifficulty
  }

  minFee: {
    type: Number
    default: config.minFee
  }

  mempool: [TransactionSchema]

  height: {type:Number,default:0},

  ctime: {type:Number,default:time()}

},{versionKey:false,strict:true})

BlockchainSchema.pre 'save', (next) ->
  @log 'saving chain'
  return next()

BlockchainSchema.methods.log = (x...) ->
  x.unshift("blockchain".blue)
  log x... 

BlockchainSchema.methods.info = -> @toJSON()

BlockchainSchema.methods.sync = ->
  start = time('ms')
  @log 'sync() start' 

  exists = await Blockchain.findOne {_id:@_id}

  if !exists
    log 'Creating new blockchain', @_id
    await @save()

  await @createGenesisBlock()

  @log 'sync() done', time('ms') - start + 'ms' 

  return true

BlockchainSchema.methods.createGenesisBlock = ->
  exists = await Block.findOne({
    _id: 0
    blockchain: @_id
  })

  if not exists 
    @log 'creating and mining genesis block'
    b = new Block(_.clone config.genesisBlock)
    await b.mine()
    await b.save()

  return true

BlockchainSchema.methods.mineBlock = (rewardAddress) ->
  height = await @getHeight()

  mempoolSorted = _.sortBy @mempool, (a,b) -> 
    (a.fee ? 0 > b.fee ? 0) 

  calculatedReward = @getMiningReward(height)
  calculatedDifficulty = await @getCurrentDifficulty(height)

  changes = {}

  if calculatedReward isnt @miningReward
    @miningReward = calculatedReward
    await @save()

  if calculatedDifficulty isnt @difficulty
    @difficulty = calculatedDifficulty
    await @save()

  blockTransactions = []

  rewardTransaction = { 
    to: rewardAddress 
    amount: calculatedReward
    comment: 'BLOCK_REWARD'
  }

  blockSize = JSON.stringify(rewardTransaction).length

  fees = 0
  for transaction in mempoolSorted 
    transactionSize = JSON.stringify(transaction).length

    if blockSize + transactionSize <= config.maxBlockSize and blockTransactions.length < config.maxTransactionsPerBlock
      fees += transaction.fee if transaction.fee?

      blockTransactions.push(transaction)
      blockSize += transactionSize
    else
      break

  rewardTransaction = new Transaction(rewardTransaction)
  rewardTransaction.amount += fees

  rewardTransaction = rewardTransaction.toJSON()
  blockTransactions.push(rewardTransaction)

  newBlock = new Block({
    txns: (_.map blockTransactions, (x) -> x)
    hash_previous: realDoc?.hash ? config.genesisBlock.hash
    difficulty: @difficulty 
  })

  start = time()
  @log 'mining block', newBlock.toJSON() 

  try
    await newBlock.mine()
  catch e
    @log 'mining error', e 
    return e

  @log 'blocked mined', time() - start + 's'
  
  processed_mempool_items = (_.compact _.map @mempool, (x) ->
    if x in blockTransactions then return x._id 
    return null
  )

  @log 'saving new block', newBlock.toJSON()
  await newBlock.save()

  @.mempool = _.reject @mempool, (transaction) ->
    transaction._id in processed_mempool_items

  @height = obj.height 

  await @save()

BlockchainSchema.methods.getMiningReward = (blockHeight) ->
  rewardHalvingInterval = config.rewardHalvingInterval
  halvings = _.floor(blockHeight / rewardHalvingInterval)
  reward = config.initialReward / (2 ** halvings)
  return reward

BlockchainSchema.methods.getCurrentMiningReward = ->
  return @getMiningReward(@height)

BlockchainSchema.methods.getCurrentDifficulty = (chainLength) ->
  adjustmentInterval = config.difficultyAdjustmentInterval

  if chainLength % adjustmentInterval isnt 0 or chainLength is 0
    return @difficulty

  blocks = await Block
    .find({blockchain:@blockchain}, ctime: 1)
    .sort(_id: -1)
    .limit(adjustmentInterval)
    .lean()

  firstBlock = blocks[blocks.length - 1]
  lastBlock = blocks[0]

  elapsedTime = (lastBlock.ctime - firstBlock.ctime) / 1000
  targetTime = adjustmentInterval * config.blockInterval

  actualTime = elapsedTime
  expectedTime = targetTime

  difficultyRatio = actualTime / expectedTime
  maxRatio = 4
  minRatio = 0.25

  newDifficulty = @difficulty
  if difficultyRatio < minRatio
    newDifficulty = _.ceil(@difficulty / minRatio)
  else if difficultyRatio > maxRatio
    newDifficulty = _.floor(@difficulty / (difficultyRatio / maxRatio))
  else
    newDifficulty = _.floor(@difficulty * difficultyRatio)

  return newDifficulty

BlockchainSchema.methods.getLatestBlock = ->
  return await Block
    .findOne({
      blockchain: @blockchain
    })
    .sort({ _id: -1 })
    .lean()
    .limit(1)

BlockchainSchema.methods.getHeight = ->
  return await @getLatestBlock()._id

BlockchainSchema.methods.getBalance = (address) ->
  blocks = await Block.find({
    blockchain: @blockchain
    txns: {
      $elemMatch: {
        $or: [
          { to: address }
          { from: address }
        ]
      }
    }
  })
  .sort {_id:1}
  .lean()

  if !blocks.length then return 0

  balance = 0

  for block in blocks
    for txn in block.txns
      if txn.to is address
        balance += txn.amount
      if txn.from is address
        balance -= (txn.amount + (txn.fee ? 0))

  return balance

BlockchainSchema.methods.getMempoolDebt = (address) ->
  amount = 0
  for txn in @mempool
    if txn.from is address
      amount += (txn.amount + txn.fee)
  return amount 

BlockchainSchema.methods.getMempoolCredit = (address) ->
  amount = 0
  for txn in @mempool
    if txn.to is address
      amount += (txn.amount)
  return amount 

BlockchainSchema.methods.addTransaction = (transactionObj,wallet) ->
  txn = new Transaction(transactionObj) 
  txn = wallet.signTransaction(txn)

  balance = await @getBalance(wallet.address)
  balance -= await @getMempoolDebt(wallet.address)

  if balance < (txn.amount + txn.fee)
    throw new Error 'Insufficient balance', balance

  if txn.isValid()
    await Blockchain.updateOne({_id:@_id},{$addToSet:{mempool:txn}})
    log 'Transaction added to mempool', txn

Blockchain = mongoose.model 'Blockchain', BlockchainSchema 
module.exports = Blockchain 
