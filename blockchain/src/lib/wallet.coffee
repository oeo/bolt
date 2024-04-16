{ env, exit } = process
{ log } = console

config = require './../config'

_ = require 'lodash'
ec = require 'elliptic'
bip39 = require 'bip39'
hdkey = require 'hdkey'

helpers = require './helpers'

{
  DERIVATION_DEFAULT
  createHash
  buildDerivationPath
  base_encode
  base_decode
} = helpers

class Wallet

  constructor: (opt = {}) ->
    defaults = {
      seedPhrase: null
      privateKeyString: null
      derivationPath: DERIVATION_DEFAULT
    }

    options = Object.assign({}, defaults, opt)

    @seedPhrase = options.seedPhrase ? opt.seed
    @privateKeyString = options.privateKeyString ? opt.privateKey
    @derivationPath = options.derivationPath ? opt.path
    @mnemonic = null

    if @seedPhrase
      @initFromSeedPhrase()
    else if @privateKeyString
      @initFromPrivateKey()
    else
      @initNew()

  use: (blockchain) -> @_blockchain = blockchain

  initNew: ->
    seedPhrase = bip39.generateMnemonic()
    seed = bip39.mnemonicToSeedSync(seedPhrase)

    @hdwallet = hdkey.fromMasterSeed(seed)
    @mnemonic = seedPhrase

    derivationPath = "m/#{@derivationPath.purpose}'/#{@derivationPath.coinType}'/#{@derivationPath.account}'/#{@derivationPath.change}/#{@derivationPath.index}"
    masterKey = @hdwallet.derive(derivationPath)

    @keyPair = new ec.ec('secp256k1').keyFromPrivate(masterKey.privateKey.toString('hex'))
    @updateKeyInfo()

  initFromSeedPhrase: ->
    seed = bip39.mnemonicToSeedSync(@seedPhrase)

    @hdwallet = hdkey.fromMasterSeed(seed)
    @mnemonic = @seedPhrase

    derivationPath = "m/#{@derivationPath.purpose}'/#{@derivationPath.coinType}'/#{@derivationPath.account}'/#{@derivationPath.change}/#{@derivationPath.index}"
    masterKey = @hdwallet.derive(derivationPath)

    @keyPair = new ec.ec('secp256k1').keyFromPrivate(masterKey.privateKey.toString('hex'))
    @updateKeyInfo()

  initFromPrivateKey: ->
    @keyPair = new ec.ec('secp256k1').keyFromPrivate(@privateKeyString)
    @updateKeyInfo()

  updateKeyInfo: ->
    keyInfo = @getKeyInfo()

    for k, v of keyInfo
      this[k] = v

  getKeyInfo: (keyPair = @keyPair) ->
    if !keyPair
      throw new Error 'No keyPair provided'

    return {
      privateKey: keyPair.getPrivate('hex')
      publicKey: keyPair.getPublic(false, 'hex')

      addressHash: createHash(keyPair.getPublic(false, 'hex'))
      addressLong: createHash(keyPair.getPublic(false, 'hex')).substr(0, 34)
      addressShort: addressShort = base_encode(58, createHash(keyPair.getPublic(false, 'hex')).substr(0, 34))
      address: addressShort
    }

  createAddresses: (opt = {}) ->
    defaults = {
      account: 0
      change: 0
      count: 10
      indexStart: 0
    }

    options = Object.assign({}, defaults, opt)

    addresses = []

    for index in [options.indexStart...(options.indexStart + options.count)]
      path = buildDerivationPath
        account: options.account
        change: options.change
        index: index

      derivedKey = @hdwallet.derive(path)
      keyPair = new ec.ec('secp256k1').keyFromPrivate(derivedKey.privateKey.toString('hex'))
      keyInfo = @getKeyInfo(keyPair)
      keyInfo.path = path

      addresses.push(keyInfo)

    addresses

  # sign and add transaction hash
  signTransaction: (transaction) ->
    if transaction.from and !@isAddressMine(transaction.from)
      throw new Error 'Cannot sign transaction from another wallet'

    transaction.publicKey = @publicKey

    hash = transaction.hash
    signatureObj = @keyPair.sign(hash)

    # Convert the signature to a hexadecimal string
    signature = signatureObj.toDER('hex')

    # Assign the signature to the transaction
    transaction.signature = signature

    transaction

  isValidAddress: (address) ->
    /^[123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]{22,34}$/.test(address)

  isAddressMine: (address) ->
    log /address/, address
    log /@getKeyInfo().address/, @getKeyInfo().address
    @getKeyInfo().address is address

  getBalance: (includeMempool = false) ->
    if !@_blockchain
      throw new Error 'Not connected to a chain, use `wallet.use(blockchain)`'

    result = await @_blockchain.addressBalance(@address, { includeMempool })
    return result

  toJSON: ->
    tmp = {}

    for k,v of @
      if typeof v is 'string' or k in [
        'hdwallet'
      ]
        tmp[k] = v

    return JSON.parse(JSON.stringify(tmp))

Wallet.addressFromPublicKey = (publicKey) -> (
  tmp = {
    addressHash: createHash(publicKey)
    addressLong: createHash(publicKey).substr(0, 34)
    addressShort: addressShort = base_encode(58, createHash(publicKey).substr(0, 34))
    address: addressShort
  }

  return tmp
)

module.exports = Wallet

## test
if !module.parent

  # Create a wallet with null (generate a new wallet)
  wallet1 = new Wallet()

  log 'Wallet 1:'
  log JSON.stringify wallet1, null, 2

  addresses = wallet1.createAddresses({
    account: 0
    count: 5
  })

  # Create a new wallet using the last generated child address
  walletChild = new Wallet(
    privateKey: _.last(addresses).privateKey
  )

  # Create a wallet with a mnemonic
  mnemonic = 'museum guilt range belt angry naive friend forget pipe inquiry churn force'

  wallet2 = new Wallet({
    seed: mnemonic,
  })

  log 'Wallet 2:'
  log JSON.stringify wallet2, null, 2

  # Create a wallet with a private key
  privateKey = 'c5b2471b767b2a0a1e374adaa93776e820f958a4ac6c88f93bfbac8e495cbca6'
  wallet3 = new Wallet({ privateKey })

  log 'Wallet 3:'
  log JSON.stringify wallet3, null, 2

  # Create a wallet with a custom derivation path
  derivationPath = 'm/44h/0h/0h'
  wallet4 = new Wallet({ path: derivationPath })

  log 'Wallet 4:'
  log JSON.stringify wallet4, null, 2

  # Derive a new address from a wallet
  addresses = wallet4.createAddresses({ count: 1 })

  log 'Wallet 4 (derived address):'
  log JSON.stringify addresses, null, 2

  exit 0

