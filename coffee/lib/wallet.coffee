config = require './../config'

mongoose = require 'mongoose'

crypto = require('crypto')
EC = require('elliptic').ec
ec = new EC('secp256k1')

Blockchain = require './../models/blockchain'

class Wallet

  constructor: (@privateKey = null) ->
    if @privateKey
      return @fromPrivateKey(@privateKey)
    else
      @keyPair = ec.genKeyPair()
      @publicKey = @keyPair.getPublic('hex')
      @privateKey = @keyPair.getPrivate('hex')
      @address = @createAddress()

  createAddress: ->
    publicKeyHash = crypto.createHash('sha256').update(Buffer.from(@publicKey, 'hex')).digest()
    address = crypto.createHash('ripemd160').update(publicKeyHash).digest('hex')
    return "b_#{address}"

  signTransaction: (transaction) ->
    throw new Error('You cannot sign transactions for other wallets') if transaction.from isnt @address
    hash = transaction.calculateHash()
    sig = @keyPair.sign(hash, 'hex')
    transaction.signature = sig.toDER('hex')
    transaction.publicKey = @publicKey
    return transaction

  fromPrivateKey: (privateKey) ->
    keyPair = ec.keyFromPrivate(privateKey, 'hex')
    wallet = new Wallet()
    wallet.keyPair = keyPair
    wallet.privateKey = privateKey
    wallet.publicKey = keyPair.getPublic().encode('hex')
    wallet.address = wallet.createAddress()
    return wallet

  fromPublicKey: (publicKey) ->
    keyPair = ec.keyFromPublic(publicKey,'hex')
    wallet = new Wallet()
    wallet.keyPair = keyPair
    wallet.publicKey = publicKey
    wallet.address = wallet.createAddress()
    return wallet

  use: (blockchain) -> @_blockchain = blockchain

  getBalance: (includeMempool=false) ->
    if !@_blockchain
      throw new Error 'Not connected to a chain, use `wallet.use(blockchain)`'

    balance = await @_blockchain.getBalance(@address)

    if !includeMempool
      return balance
    else
      return {
        onChain: balance
        mempoolCredit: await @_blockchain.getMempoolCredit(@address)
        mempoolDebt: await @_blockchain.getMempoolDebt(@address)
      }


module.exports = Wallet
