config = require './../config'

mongoose = require 'mongoose'

{Transaction,TransactionSchema} = require './transaction'

merkle = require './../lib/merkle'
{timeBucket,sha256} = require './../lib/helpers'

{scryptAsync} = require('@noble/hashes/scrypt')

BlockSchema = new mongoose.Schema({

  _id: {
    type: Number
  }

  txns: {
    type: [TransactionSchema],
  },

  comment: {
    type: String
    default: null
  }

  version: {
    type: String 
    default: config.version
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
    default: -> timeBucket(10)
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

}, {id:false,versionKey:false,strict:true})

maxTarget = BigInt('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF')
getTargetForDifficulty = (difficulty) -> maxTarget / BigInt(difficulty)

BlockSchema.pre 'save', (next) ->
  count = await Block.count {version:@version}
  @_id = count
  next()

# calculate block hash 
BlockSchema.methods.calculateHash = (returnString = false) ->
  str = [
    "#{@version}"
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
BlockSchema.methods.validateHash = ->
  target = getTargetForDifficulty(@difficulty)
  {hashBuf, hashBigInt} = await @calculateHash()

  recomputedHash = Buffer.from(hashBuf).toString('hex')
  return false if recomputedHash isnt @hash

  return true if hashBigInt < target
  return false

BlockSchema.methods.mineBlock = (->
  target = getTargetForDifficulty(@difficulty)

  _mine = () =>
    {hashBuf, hashBigInt} = await @calculateHash()
    if hashBigInt < target
      @hash = Buffer.from(hashBuf).toString('hex')
      log 'Solved block', @toJSON(), @hash 
      return @hash
    else
      @nonce = @nonce + 1
      _mine()

  return _mine()
)

Block = mongoose.model 'Block', BlockSchema 
module.exports = Block 
