config = require './../config'

crypto = require 'crypto'
ec = require 'elliptic'
bip39 = require 'bip39'
hdkey = require 'hdkey'

class Wallet

  constructor: (seedPhrase, privateKeyString) ->
    if privateKeyString?
      @keyPair = new ec.ec('secp256k1').keyFromPrivate(privateKeyString)
    else
      if not seedPhrase?
        seedPhrase = bip39.generateMnemonic()

      seed = bip39.mnemonicToSeedSync(seedPhrase)
      hdwallet = hdkey.fromMasterSeed(seed)

      @keyPair = new ec.ec('secp256k1').keyFromPrivate(hdwallet.privateKey.toString('hex'))
      @mnemonic = seedPhrase

    @privateKey = @getPrivateKey()
    @publicKey = @getPublicKey()
    @address = @getAddress()

    @toJSON = (=>
      tmp = {}
      for k,v of @
        if typeof v is 'string'
          tmp[k] = v
      return tmp
    )

    return @

  use: (blockchain) -> @_blockchain = blockchain

  getPrivateKey: ->
    @keyPair.getPrivate('hex')

  getPublicKey: ->
    @keyPair.getPublic(false, 'hex')

  getAddress: ->
    publicKey = @getPublicKey()
    hash = crypto.createHash('sha256').update(publicKey, 'hex').digest('hex')
    address = 'b_' + hash.substring(0, 34)
    address

  signTransaction: (transaction) ->
    if transaction.fromAddress != @address
      throw new Error 'Cannot sign transactions for other wallets'

    hash = transaction.calculateHash()
    signature = @keyPair.sign(hash, 'hex')
    transaction.sign(signature)

    return transaction

  getBalance: (includeMempool = false) ->
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

if !module.parent 

  # Create a wallet with null (generate a new wallet)
  wallet1 = new Wallet()
  console.log 'Generated Wallet Mnemonic:', wallet1.mnemonic
  console.log 'Generated Wallet Private Key:', wallet1.privateKey
  console.log 'Generated Wallet Address:', wallet1.address

  # Create a wallet with a mnemonic
  mnemonic = 'museum guilt range belt angry naive friend forget pipe inquiry churn force'
  wallet2 = new Wallet(mnemonic)
  console.log 'Wallet 2 Mnemonic:', wallet2.mnemonic
  console.log 'Wallet 2 Private Key:', wallet2.privateKey
  console.log 'Wallet 2 Address:', wallet2.address

  # Create a wallet with a private key
  privateKey = 'c5b2471b767b2a0a1e374adaa93776e820f958a4ac6c88f93bfbac8e495cbca6'
  wallet3 = new Wallet(null, privateKey)
  console.log 'Wallet 3 Mnemonic:', wallet3.mnemonic
  console.log 'Wallet 3 Private Key:', wallet3.privateKey
  console.log 'Wallet 3 Address:', wallet3.address
