config = require './../config'

mongoose = require 'mongoose'

{Transaction,TransactionSchema} = require './transaction'

merkle = require './../lib/merkle'
{time,timeBucket,sha256} = require './../lib/helpers'

{scryptAsync} = require('@noble/hashes/scrypt')

BlockSchema = new mongoose.Schema({

  _id: Number

  blockchain: {
    type: String
    ref: 'Blockchain'
    default: config.version
  }

  txns: {
    type: [TransactionSchema],
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
    default: -> merkle(this.txns)
  } 

  ctime: {
    type: Number
    default: -> time() 
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

}, {versionKey:false,strict:true})

maxTarget = BigInt('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF')
getTargetForDifficulty = (difficulty) -> maxTarget / BigInt(difficulty)

# determine my own block id
BlockSchema.pre 'save', (next) ->
  @_id = await Block.count({
    blockchain: @blockchain
  }).lean() 

  next()

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

  hashBuf = await scryptAsync(str, '', { N: 1024, r: 8, p: 1, dkLen: 32 })
  hashBigInt = BigInt("0x#{Buffer.from(hashBuf).toString('hex')}")

  if returnString
    return Buffer.from(hashBuf).toString('hex')
  else
    return {hashBuf, hashBigInt}

# validate this block hash is correct
BlockSchema.methods.verifyHash = ->
  target = getTargetForDifficulty(@difficulty)
  {hashBuf, hashBigInt} = await @calculateHash()

  recomputedHash = Buffer.from(hashBuf).toString('hex')
  return false if recomputedHash isnt @hash

  return true if hashBigInt < target
  return false

BlockSchema.methods.mine = (->
  target = getTargetForDifficulty(@difficulty)

  _mine = () =>
    {hashBuf, hashBigInt} = await @calculateHash()
    if hashBigInt < target
      @hash = Buffer.from(hashBuf).toString('hex')
      log 'Solved block', @toJSON() 
      return @hash
    else
      @nonce = @nonce + 1
      _mine()

  return _mine()
)

Block = mongoose.model 'Block', BlockSchema 
module.exports = Block 
