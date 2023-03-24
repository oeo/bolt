config = require './../config'

mongoose = require 'mongoose'

Block = require './block'
{Transaction,TransactionSchema} = require './transaction'

{time,timeBucket,sha256} = require './../lib/helpers'

BlockchainSchema = new mongoose.Schema({

  _id: {
    type: String
    required:true
    default: config.version
  }

  default: {
    type: Boolean
    default: true
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

  time_last_block: {type:Number,default:0} 
  time_last_rewardUpdate: {type:Number,default:0} 
  time_last_difficultyUpdate: {type:Number,default:0}

  ctime: {type:Number,default:time()}

},{versionKey:false,strict:true})

BlockchainSchema.pre 'save', (next) ->
  if @isNew
    log 'Created new Blockchain', @toJSON()
    await @createGenesisBlock()

  next()

BlockchainSchema.methods.createGenesisBlock = ->
  block = await Block.findOne({}).sort({ _id: -1 }).limit(1)

  if not block
    b = new Block(_.clone config.genesisBlock)
    log 'Mining Genesis block'
    await b.mineBlock()
    await b.save()

BlockchainSchema.methods.mineBlock = (rewardAddress) ->
  realDoc = await Block.findOne({}).sort({ _id: -1 }).limit(1)
  height = realDoc._id

  # sort mempool by best fees
  mempoolSorted = _.sortBy @mempool, (a,b) -> 
    (a.fee ? 0 > b.fee ? 0) 

  # calculate reward and difficulty for block
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
    difficulty: calculatedDifficulty
  })

  log 'Mining a block', {
    transactions: blockTransactions.length
    reward: calculatedReward
    difficulty: calculatedDifficulty
  }

  await newBlock.mineBlock()
  
  processed_mempool_items = (_.compact _.map @mempool, (x) ->
    if x in blockTransactions then return x._id 
    return null
  )

  await newBlock.save()
  await Blockchain.updateOne(
    { _id: @_id },
    {
      $pull: {
        mempool: { _id: { $in: processed_mempool_items } }
      }
      $inc: {
        height: 1
      }
    }
  )

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
    .find({}, ctime: 1)
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

BlockchainSchema.methods.xgetCurrentDifficulty = ->
  realDoc = await Block.findOne({}).sort({ _id: -1 }).lean().limit(1)
  chainLength = realDoc._id

  adjustmentInterval = config.difficultyAdjustmentInterval
  
  if chainLength % adjustmentInterval isnt 0 or chainLength is 0
    return @difficulty
  
  blocks = await Block
    .find({}, {hash_merkle: 1, ctime: 1})
    .sort({_id: -1})
    .limit(adjustmentInterval)
    .lean()
  
  firstBlock = _.last(blocks)
  lastBlock = _.first(blocks)
  
  elapsedTime = (lastBlock.ctime - firstBlock.ctime) / 1000
  targetTime = adjustmentInterval * config.blockInterval
  
  actualTime = _.sumBy(blocks, 'ctime') / 1000
  expectedTime = targetTime * adjustmentInterval
  
  difficultyRatio = actualTime / expectedTime
  maxRatio = 4
  
  if difficultyRatio > maxRatio
    return _.floor(@difficulty / (difficultyRatio / maxRatio))
  
  return _.floor(@difficulty * difficultyRatio)

BlockchainSchema.methods.getBalance = (address) ->
  blocks = await Block.find({
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

BlockchainSchema.statics.connect = ->
  blockchain = await Blockchain.findOne {default:true}

  if !blockchain
    blockchain = new Blockchain()
    await blockchain.save()
  else
    await blockchain.createGenesisBlock()

  return blockchain

Blockchain = mongoose.model 'Blockchain', BlockchainSchema 
module.exports = Blockchain 
