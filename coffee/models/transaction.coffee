config = require './../config'

{timeBucket,sha256,uuid} = require './../lib/helpers'

mongoose = require 'mongoose'

EC = require('elliptic').ec
ec = new EC('secp256k1')

TransactionSchema = new mongoose.Schema({

  _id: {
    type: String
    default: -> uuid()
  }

  from: {type:String} 
  to: {type:String,required:true}

  fee: {
    type: Number
    default: config.minFee
    min: config.minFee
  }

  amount: {type:Number,default:0}

  comment: {
    type: String
    default: null
    maxLength: config.maxTransactionCommentSize
  }

  publicKey: {type:String}
  signature: {type:String}

}, {versionKey:false})

TransactionSchema.methods.calculateHash = ->
  return sha256([
    @from
    @to
    @amount
    @fee
    @comment
  ].join('')) 

TransactionSchema.methods.isValid = ->
  if !@from then return true 

  if !@signature
    throw new Error 'No signature found on transaction'

  keyPair = ec.keyFromPublic(@publicKey, 'hex')

  if !keyPair
    throw new Error 'Invalid publicKey on transaction'

  return keyPair.verify(@calculateHash(), @signature)

Transaction = mongoose.model 'Transaction', TransactionSchema
module.exports = {Transaction,TransactionSchema}
