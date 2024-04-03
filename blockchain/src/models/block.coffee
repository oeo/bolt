config = require './../config'

mongoose = require 'mongoose'

{ Transaction, TransactionSchema } = require './transaction'

merkle = require './../lib/merkle'

{
  time,
  createHash,
  calculateBlockReward,
  calculateBlockDifficulty,
} = require './../lib/helpers'

BlockSchema = new mongoose.Schema({

  _id: Number

  blockchain: {
    type: String
    ref: 'Blockchain'
    default: config.version
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

}, {versionKey:false,strict:true})

maxTarget = BigInt('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF')
getTargetForDifficulty = (difficulty) -> maxTarget / BigInt(difficulty)

# determine my own block id
BlockSchema.pre 'save', (next) ->
  if !@isValid()
    return next new Error 'Block is not valid'

  lastBlock = await Block
    .findOne({blockchain:@blockchain})
    .sort({_id:-1})
    .limit(1)

  if lastBlock
    if @_id isnt (lastBlock._id + 1)
      return next new Error 'Block height is invalid'

    @time_elapsed = @ctime - lastBlock.ctime
  else
    @time_elapsed = 0

  next()

BlockSchema.post 'save', (doc) ->
  eve.emit 'block_solved', {
    height: doc._id
    blockchain: doc.blockchain
  }

  await mongoose.model('Blockchain')
    .updateOne {_id: doc.blockchain}
    .set {
      height: doc._id
      difficulty: doc.difficulty
      time_last_block: doc.ctime
    }

# calculate block hash 
BlockSchema.methods.calculateHash = (returnString = false) ->
  str = [
    "#{@blockchain}"
    "#{@hash_previous}"
    "#{@hash_merkle}"
    "#{@ctime}"
    "#{@difficulty}"
    "#{@nonce}"
  ].join('')

  hashBuf = createHash(str, {
    type: config.algo
  })

  hashBigInt = BigInt("0x#{Buffer.from(hashBuf).toString('hex')}")

  if returnString
    return Buffer.from(hashBuf).toString('hex')
  else
    return {hashBuf, hashBigInt}

BlockSchema.methods.calculateBlockDifficulty = (height = 0) ->
  return await calculateBlockDifficulty(@blockchain,height)

BlockSchema.methods.calculateBlockReward = (height = 0) ->
  return await calculateBlockReward(height)

# validate the block
BlockSchema.methods.isValid = ->

  # check hash 
  target = getTargetForDifficulty(@difficulty)
  {hashBuf, hashBigInt} = await @calculateHash()

  recomputedHash = Buffer.from(hashBuf).toString('hex')

  if recomputedHash isnt @hash
    return new Error '`hash` invalid'

  hashValid = hashBigInt < target
  return new Error('`hashBigInt` invalid (too small)') if !hashValid

  # check difficulty 
  if @difficulty isnt (await calculateBlockDifficulty(@blockchain,@_id))
    return new Error '`difficulty` invalid'

  # check reward 
  if @transactions.length
    rewardItem = _.find(@transactions,{ from: null, comment: 'block_reward' })
    if rewardItem.amount isnt (await calculateBlockReward(@_id))
      return new Error '`minerReward` invalid'

  # check merkle
  if @hash_merkle isnt merkle(@transactions)
    return new Error '`hash_merkle` is invalid'

  # block valid 
  return true

BlockSchema.methods.xmine = (->
  _mine = () =>
    target = getTargetForDifficulty(@difficulty)
    { hashBuf, hashBigInt } = await @calculateHash()

    if hashBigInt < target
      @hash = Buffer.from(hashBuf).toString('hex')
      return @hash
    else
      @nonce = @nonce + 1
      _mine()

  return _mine()
)

BlockSchema.methods.mine = ->
  miningCanceled = false

  _height = @_id
  _blockchain = @blockchain

  cancelMining = new Promise (resolve) =>
    eve.once 'block_solved', (data) =>
      if data.height is _height and data.blockchain is _blockchain
        miningCanceled = true
        resolve()

  delay = (ms) ->
    new Promise (resolve) -> setTimeout resolve, ms

  # Convert the recursive mining function to a while loop
  _mine = =>
    target = getTargetForDifficulty(@difficulty)
    iterationsBeforeCheckingCancel = 250

    while not miningCanceled
      for i in [1..iterationsBeforeCheckingCancel] by 1
        {hashBuf, hashBigInt} = await @calculateHash()

        if hashBigInt < target
          @hash = Buffer.from(hashBuf).toString('hex')
          return @hash
        else
          @nonce = @nonce + 1

      await Promise.race([delay(50), cancelMining])

    return null

  return _mine()

Block = mongoose.model 'Block', BlockSchema
module.exports = Block

