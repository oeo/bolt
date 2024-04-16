# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
config = require './../config'

mongoose = require 'mongoose'
{ EXPOSE } = require './../lib/models'

{ Transaction, TransactionSchema } = require './transaction'

merkle = require './../lib/merkle'

{
  time
  sleep
  createHash
  calculateBlockDifficulty
  calculateBlockReward
} = require './../lib/helpers'

modelOpts = {
  name: 'Block'
  schema: {
    versionKey: false
    collection: 'blocks'
    strict: true
  }
}

BlockSchema = new mongoose.Schema({

  _id: {
    type: Number
    required: true
  }

  blockchain: {
    type: Number
    required: true
    default: config.versionInt
  }

  transactions: {
    type: [TransactionSchema],
    default: []
  },

  comment: {
    type: String
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
    default: config.difficultyDefault
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

}, modelOpts.schema)

maxTarget = BigInt('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF')
getTargetForDifficulty = (difficulty) -> maxTarget / BigInt(difficulty)

# determine my own block id
BlockSchema.pre 'save', ((next) ->
  try
    await @tryValidate()
  catch e
    return next e

  _time = time()

  lastBlock = await @constructor.findOne(_id: @_id - 1)
  @time_elapsed = @ctime - lastBlock?.ctime ? 0

  return next()
)

BlockSchema.post 'save', (doc) ->
  eve.emit 'block_solved', {
    height: doc._id
  }

# calculate block hash 
BlockSchema.methods.calculateHash = ->
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
  return await calculateBlockDifficulty(height)

BlockSchema.methods.calculateBlockReward = (height = 0) ->
  return await calculateBlockReward(height)

BlockSchema.methods.isValid = (opt = {}) ->
  try
    await @tryValidate(opt)
    return true
  catch e
    return false

BlockSchema.methods.tryValidate = (opt = {}) ->

  # validate genesis block
  if @_id is 0
    if @hash isnt config.genesisBlock.hash
      throw new Error '`hash` invalid for genesis block'
    if @hash_previous isnt config.genesisBlock.hash_previous
      throw new Error '`hash_previous` invalid for genesis block'
    if @difficulty isnt config.genesisBlock.difficulty
      throw new Error '`difficulty` invalid for genesis block'
    
    # Genesis block is valid
    return true

  # validate the block against the previous block
  if opt.prevBlock
    prevBlock = opt.prevBlock
  else
    prevBlock = await @constructor.findOne(_id: @_id - 1)

  if !prevBlock
    throw new Error 'previous block not found'

  # check hash match
  if @hash_previous isnt prevBlock.hash
    throw new Error '`hash_previous` invalid'

  # recalculate the hash
  target = getTargetForDifficulty(@difficulty)
  { hashStr, hashBigInt } = await @calculateHash()

  if hashStr isnt @hash
    throw new Error '`hash` invalid'

  # make sure the merkle hash matches
  if @hash_merkle isnt merkle(@transactions)
    throw new Error '`hash_merkle` is invalid'

  # check difficulty
  hashValid = hashBigInt < target

  if !hashValid
    throw new Error('`hashBigInt` invalid (too small)')

  # ensure the difficulty is correct
  if @difficulty isnt (cdifficulty = await calculateBlockDifficulty(@_id))
    throw new Error "`difficulty` invalid: (difficulty=#{@difficulty}, cdifficulty=#{cdifficulty})"

  # Check reward transactions
  if @transactions.length
    rewardItems = _.filter(@transactions, { from: null, comment: 'block_reward' })

    if rewardItems.length isnt 1
      throw new Error 'Invalid number of block reward transactions'

    rewardItem = rewardItems[0]

    if rewardItem.amount isnt (await calculateBlockReward(@_id))
      throw new Error '`minerReward` invalid'

  # valid block 
  return true

# Local mining function
BlockSchema.methods.mine = ->
  miningCanceled = false

  _height = @_id
  _blockchain = @blockchain

  cancelMining = new Promise (resolve) =>
    eve.once 'block_solved', (data) =>
      if data.height is _height
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

      await Promise.race([sleep(50), cancelMining])

    return null

  return _mine()

model = mongoose.model modelOpts.name, BlockSchema
module.exports = EXPOSE(model)

