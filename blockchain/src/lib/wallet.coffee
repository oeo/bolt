config = require './../config'

ec = require 'elliptic'
bip39 = require 'bip39'
hdkey = require 'hdkey'

{
  createHash
  buildDerivationPath
  base_encode
  base_decode
} = require './helpers'

class Wallet

  constructor: (opt = {
    seedPhrase: null
    privateKeyString: null
    derivationPath: config.derivationPath
  }) ->
    defaults = {
      seedPhrase: opt.seed ? null
      privateKeyString: opt.privateKey ? null
      derivationPath: opt.path ? config.derivationPath ? null
    }

    for k,v of defaults
      opt[k] ?= v

    @opt = opt

    @new = false
    @mnemonic = null

    if !opt.seedPhrase and !opt.privateKeyString
      @new = true

      seedPhrase = bip39.generateMnemonic()
      seed = bip39.mnemonicToSeedSync(seedPhrase)

      @hdwallet = hdkey.fromMasterSeed(seed)
      @mnemonic = seedPhrase

      masterKey = @hdwallet.derive('m')
      @keyPair = new ec.ec('secp256k1').keyFromPrivate(masterKey.privateKey.toString('hex'))

    if opt.privateKeyString and !opt.seedPhrase
      @keyPair = new ec.ec('secp256k1').keyFromPrivate(opt.privateKeyString)

    if opt.seedPhrase and !opt.privateKeyString
      seed = bip39.mnemonicToSeedSync(@opt.seedPhrase)

      @hdwallet = hdkey.fromMasterSeed(seed)
      @mnemonic = @opt.seedPhrase

      masterKey = @hdwallet.derive('m')
      @keyPair = new ec.ec('secp256k1').keyFromPrivate(masterKey.privateKey.toString('hex'))

    keyInfo = @getKeyInfo(@keyPair)

    for k,v of keyInfo
      this[k] = v

    @toJSON = (=>
      tmp = {}
      for k,v of @
        if typeof v is 'string' or k in [
          'new'
          'hdwallet'
        ]
          tmp[k] = v
      return tmp
    )

    return @

  use: (blockchain) -> @_blockchain = blockchain

  getKeyInfo: (keyPair = null) ->
    if !keyPair then keyPair = @keyPair
    if !@keyPair then throw new Error 'No keyPair provided'

    tmp = {
      privateKey: keyPair.getPrivate 'hex'
      publicKey: keyPair.getPublic false, 'hex'
    }

    tmp.address = createHash tmp.publicKey
    tmp.address = tmp.address.substr 0, 34

    tmp.addressShort = 'bolt' + base_encode(58, tmp.address)
    tmp.address = 'bolt' + tmp.address

    tmp.addresses = [
      tmp.address
      tmp.addressShort
    ]

    return tmp

  createAddresses: (opt = {
    account: 0
    change: 0
    count: 0
    indexStart: 0
  }) ->
    defaults = {
      account: opt.account ? 0
      change: opt.change ? 0
      count: opt.count ? 10
      indexStart: opt.indexStart ? 0
    }

    for k,v of defaults
      opt[k] ?= v

    addresses = []

    for index in [opt.indexStart...opt.indexStart + opt.count]
      path = buildDerivationPath {
        account: opt.account,
        change: opt.change,
        index: index
      }
      derivedKey = @hdwallet.derive(path)
      keyPair = new ec.ec('secp256k1').keyFromPrivate(derivedKey.privateKey.toString('hex'))
      keyInfo = @getKeyInfo keyPair
      addr = keyInfo
      addr.path = path
      addresses.push addr

    return addresses

  signTransaction: (transaction) ->
    if transaction.fromAddress !in @addresses
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

  # Check if address is valid
  isValidAddress: (address) ->
    if address.startsWith('bold')
      address = address.substr(0, 4)
    addressRegex = /[123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]{22,34}$/
    addressRegex.test(address)

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

