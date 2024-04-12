# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
config = require './../config'

mongoose = require 'mongoose'

{ Transaction, TransactionSchema } = require './transaction'

merkle = require './../lib/merkle'
helpers = require './../lib/helpers'

{
  time
  createHash
  calculateBlockReward
  calculateBlockDifficulty
} = require './../lib/helpers'

BlockSchema = new mongoose.Schema({

  _id: {
    type: Number
    required: true
  }

  blockchain: {
    type: String
    ref: 'Blockchain'
    default: config.versionInt
  }

  transactions: {
    type: [TransactionSchema],
    default: []
  },

  comment: {
    type: String
    default: null
  }

  hash: {
    type: String
    required: true
    default: null
  }

  hash_previous: {
    type: String
    required: true
    default: null
  }

  hash_merkle: {
    type: String
    default: -> merkle(this.transactions)
  }

  difficulty: {
    type: Number
    min: 1
    required: true
  }

  nonce: {
    type: Number
    default: 0
    required: true
  }

  time_elapsed: {
    type: Number
    default: 0
  }

  ctime: {
    type: Number
    default: -> time()
  }

}, { versionKey: false, strict: true })

maxTarget = BigInt('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF')
getTargetForDifficulty = (difficulty) -> maxTarget / BigInt(difficulty)

# determine my own block id
BlockSchema.pre 'save', ((next) ->
  try
    await @tryValidate()
  catch e
    return next e

  _time = time()

  lastBlock = await Block
    .findOne({ blockchain: @blockchain })
    .sort({ _id: -1 })

  @time_elapsed = @ctime - lastBlock?.ctime ? 0

  return next()
)

BlockSchema.post 'save', (doc) ->
  eve.emit 'block_solved', {
    height: doc._id
    blockchain: doc.blockchain
  }

  await mongoose.model('Blockchain')
    .updateOne { _id: doc.blockchain }
    .set {
      height: doc._id
      difficulty: doc.difficulty
      time_last_block: doc.ctime
    }

# calculate block hash 
BlockSchema.methods.calculateHash = (returnString = false) ->
  str = _.compact([
    "#{@_id}"
    "#{@blockchain}"
    "#{@hash_previous}"
    "#{@hash_merkle}"
    "#{@difficulty}"
    "#{@nonce}"
  ]).join('')

  hashStr = createHash(str, {
    type: config.algo
  })

  hashBigInt = BigInt("0x#{hashStr}")

  return { hashStr, hashBigInt }

BlockSchema.methods.calculateBlockDifficulty = (height = 0) ->
  return await calculateBlockDifficulty(@blockchain, height)

BlockSchema.methods.calculateBlockReward = (height = 0) ->
  return await calculateBlockReward(height)

# validation
BlockSchema.methods.isValid = ->
  try
    await @tryValidate()
    return true
  catch e
    return false

BlockSchema.methods.tryValidate = ->

  # Get last block
  lastBlock = await Block
    .findOne({ blockchain: @blockchain })
    .sort({ _id: -1 })

  if lastBlock

    # Check last block hash
    if @hash_previous isnt lastBlock.hash
      throw new Error '`hash_previous` invalid'

    # Check block height
    if @_id isnt lastBlock._id + 1
      throw new Error '`_id` (block height) invalid'

  # Check hash 
  target = getTargetForDifficulty(@difficulty)
  { hashStr, hashBigInt } = await @calculateHash()

  if hashStr isnt @hash
    throw new Error '`hash` invalid'

  hashValid = hashBigInt < target

  if !hashValid
    throw new Error('`hashBigInt` invalid (too small)')

  # Check difficulty 
  if @difficulty isnt (await calculateBlockDifficulty(@blockchain, @_id))
    throw new Error '`difficulty` invalid'

  # Check reward transactions
  if @transactions.length
    rewardItems = _.filter(@transactions, { from: null, comment: 'block_reward' })

    if rewardItems.length isnt 1
      throw new Error 'Invalid number of block reward transactions'

    rewardItem = rewardItems[0]

    if rewardItem.amount isnt (await calculateBlockReward(@_id))
      throw new Error '`minerReward` invalid'

  # Check merkle
  if @hash_merkle isnt merkle(@transactions)
    throw new Error '`hash_merkle` is invalid'

  # Block is valid 
  return true

# Local mining function
BlockSchema.methods.mine = ->
  miningCanceled = false

  _height = @_id
  _blockchain = @blockchain

  cancelMining = new Promise (resolve) =>
    eve.once 'block_solved', (data) =>
      if data.height is _height and data.blockchain is _blockchain
        miningCanceled = true
        resolve()

  # Convert the recursive mining function to a while loop
  _mine = =>
    target = getTargetForDifficulty(@difficulty)
    iterationsBeforeCheckingCancel = 250

    while not miningCanceled
      for i in [1..iterationsBeforeCheckingCancel] by 1
        { hashStr, hashBigInt } = await @calculateHash()

        if hashBigInt < target
          @hash = hashStr
          return @hash
        else
          @nonce = @nonce + 1

      await Promise.race([helpers.sleep(50), cancelMining])

    return null

  return _mine()

Block = mongoose.model 'Block', BlockSchema
module.exports = Block

