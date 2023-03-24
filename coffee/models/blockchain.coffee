config = require './../config'

mongoose = require 'mongoose'

Block = require './block'
{Transaction,TransactionSchema} = require './transaction'

{timeBucket,sha256} = require './../lib/helpers'

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

  ctime: {type:Number,default:timeBucket(60)}

},{versionKey:false,strict:true})

BlockchainSchema.pre 'save', (next) ->
  if @isNew
    log 'Created new Blockchain', @toJSON()

  await @createGenesisBlock()

  next()

BlockchainSchema.methods.createGenesisBlock = ->
  exists = await Block.findOne _id:0

  if !exists
    b = new Block(_.clone config.genesisBlock)
    log 'Mining Genesis block'
    await b.mineBlock()
    await b.save()

BlockchainSchema.methods.mineBlock = (rewardAddress) ->
  fees = 0

  realDoc = await Blockchain.findOne({_id:@_id}).lean()
  height = realDoc.height
  mempool = realDoc.mempool

  for transaction in mempool
    fees += transaction.fee if transaction.fee?
  
  # Create reward transaction
  rewardTransaction = new Transaction {
    to: rewardAddress 
    amount: @miningReward + fees
    comment: 'BLOCK_MINING_REWARD'
  }

  rewardTransaction = rewardTransaction.toJSON()

  # Sort pending transactions based on their fees in descending order
  mempoolSorted = _.sortBy mempool, (a,b) -> (a.fee ? 0 > b.fee ? 0) 

  # Initialize block transactions and size
  blockTransactions = []
  blockSize = JSON.stringify(rewardTransaction).length

  # Add transactions to the block until maxBlockSize or maxTransactionsPerBlock is reached
  for transaction in mempoolSorted 
    transactionSize = JSON.stringify(transaction).length

    if blockSize + transactionSize <= config.maxBlockSize and blockTransactions.length < config.maxTransactionsPerBlock
      blockTransactions.push(transaction)
      blockSize += transactionSize
    else
      break

  # add reward txn to the end
  blockTransactions.push(rewardTransaction)

  # determine correct difficulty
  # await @adjustDifficulty()

  lastBlock = await Block.findOne _id:height 

  newBlock = new Block({
    txns: (_.map blockTransactions, (x) -> x)
    hash_previous: lastBlock.hash
    difficulty: @difficulty 
  })

  solved = await newBlock.mineBlock()

  processed_txn_ids = (_.compact _.map @mempool, (x) ->
    if x in blockTransactions then return x._id 
    return null
  )

  await Blockchain.updateOne({_id:@_id},{
    $pull:{
      mempool:{
        _id: {
          $in: processed_txn_ids
        }
      }
    }
    $inc: {height:1}
  })

  await newBlock.save()

# half mining reward
BlockchainSchema.methods.updateMiningReward = ->
  @reward /= 2
  @time_last_rewardUpdate = timeBucket(60) 
  return @save

# update difficulty if needed 
BlockchainSchema.methods.updateDifficulty = ->
  chainLength = @height

  if (chainLength - 1) % config.difficultyAdjustmentInterval == 0 && chainLength > 1
    startIndex = chainLength - 1 - config.difficultyAdjustmentInterval
    startTime = @chain[startIndex].ctime
    endTime = @chain[chainLength - 1].ctime

    timeElapsed = endTime - startTime
    targetTime = config.difficultyAdjustmentInterval * config.blockInterval

    if timeElapsed < targetTime * 0.9
      log 'Increasing difficulty'
      @difficulty *= 2
    else if timeElapsed > targetTime * 1.1
      log 'Decreasing difficulty'
      @difficulty /= 2

    @time_last_difficultyUpdate = timeBucket(60)

  return @save

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
        balance -= txn.amount - txn.fees

  return balance

# add transaction to mempool
BlockchainSchema.methods.addTransaction = (transactionObj,wallet) ->
  txn = new Transaction(transactionObj) 
  txn = wallet.signTransaction(txn)

  log /adding txn/, txn
  log /mempool/, @mempool

  if txn.isValid()
    await Blockchain.updateOne({_id:@_id},{$addToSet:{mempool:txn}})
    log 'Transaction added to mempool', txn

Blockchain = mongoose.model 'Blockchain', BlockchainSchema 
module.exports = Blockchain 
