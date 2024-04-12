# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
config = require './../config'

{
  uuid
  time
  createHash
} = require './../lib/helpers'

mongoose = require 'mongoose'

EC = require('elliptic').ec
ec = new EC('secp256k1')

Wallet = require './../lib/wallet'

TransactionSchema = new mongoose.Schema({

  blockchain: {
    type: String
    ref: 'Blockchain'
    default: config.versionInt
  }

  to: { type: String, required: true }
  from: { type: String }

  fee: {
    type: Number
    default: config.minFee
    validate: {
      validator: (val) ->
        if !this.from then return true
        if val < config.minFee then return false
    }
  }

  amount: {
    type: Number,
    default: 0
  }

  comment: {
    type: String
    default: null
    maxLength: config.maxTransactionCommentSize
  }

  ctime: {
    type: Number
    default: -> time()
  }

  hash: { type: String, default: -> @calculateHash() }
  signature: { type: String, required: true }
  publicKey: { type: String, required: true }

}, { versionKey: false, _id: false, strict: true })

TransactionSchema.methods.calculateHash = ->
  str = _.compact([
    "#{@from}"
    "#{@to}"
    "#{@amount}"
    "#{@fee}"
    "#{@comment}"
    "#{@ctime}"
    "#{@publicKey}"
  ]).join('')

  createHash(str, { type: config.algo })

TransactionSchema.methods.isValid = ->
  try
    await @tryValidate()
    return true
  catch e
    return false

TransactionSchema.methods.tryValidate = ->

  # Ensure the hash is valid
  if @hash isnt @calculateHash()
    throw new Error '`hash` invalid'

  # Ensure that the from address matches the publicKey
  addressCalc = Wallet.addressFromPublicKey(@publicKey)

  if @from !in _.values(addressCalc)
    throw new Error 'invalid `from` and `publicKey` combination'

  # Verify the signature
  keyPair = ec.keyFromPublic(@publicKey, 'hex')

  if !keyPair
    throw new Error '`publicKey` invalid'

  validSignature = keyPair.verify(@hash, @signature, 'hex')

  if !validSignature
    throw new Error '`signature` invalid'

  # @todo:
  # check to make sure this person has the balance
  # to send or we can just reject this transaction

  # Transaction is valid
  true

Transaction = mongoose.model 'Transaction', TransactionSchema

module.exports = {
  Transaction
  TransactionSchema
}

