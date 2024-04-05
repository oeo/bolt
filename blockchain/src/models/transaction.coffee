config = require './../config'

{ timeBucket, sha256, uuid, time } = require './../lib/helpers'

mongoose = require 'mongoose'

EC = require('elliptic').ec
ec = new EC('secp256k1')

TransactionSchema = new mongoose.Schema({

  _id: {
    type: String
    default: -> @calculateHash()
  }

  from: { type: String }
  to: { type: String, required:true }

  contractFn: { type:String, default:null }
  contractArgs: [{
    type: mongoose.Schema.Types.Mixed
    default: []
  }]

  fee: {
    type: Number
    default: config.minFee
    validate: {
      validator: (val) ->
        if !this.from then return true
        if val < config.minFee then return false
    }
  }

  amount: { type: Number, default: 0 }

  comment: {
    type: String
    default: null
    maxLength: config.maxTransactionCommentSize
  }

  publicKey: String
  signature: String

  ctime: {
    type: Number
    default: -> time()
  }

}, { versionKey: false })

TransactionSchema.methods.calculateHash = ->
  return sha256([
    @from
    @to
    @contractFn
    @contractArgs
    @amount
    @fee
    @comment
  ].join(''))

TransactionSchema.methods.isValid = ->
  keyPair = ec.keyFromPublic(@publicKey, 'hex')

  if !keyPair
    throw new Error 'Invalid publicKey on transaction'

  return keyPair.verify(@calculateHash(), @signature)

Transaction = mongoose.model 'Transaction', TransactionSchema
module.exports = { Transaction, TransactionSchema }

