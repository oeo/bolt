# @note: temporary override
process.env.STAGING = true

vers = require __dirname + '/lib/version'

config = {
  package: vers.package

  version: vers.package.version # ex: 0.1.13
  versionInt: vers.package.versionInt # ex: 1013

  staging: false

  storage: {
    mongo: 'mongodb://127.0.0.1:27017/' + vers.info().prefixMongo
    redis: 'redis://127.0.0.1:6379/0'
    redisPrefix: vers.info().prefixRedis
    mongoPrefix: vers.info().prefixMongo
  }

  ports: {
    ws: 9443
    http: 9442
  }

  algo: 'scrypt' # ex: [sha256, scrypt, bolthash]

  minFee: 0.001
  maxBlockSize: 1024 * 1024
  maxContractStateSize: 1024 * 1024
  maxTransactionsPerBlock: 4000
  maxTransactionCommentSize: 32
  maxBlockCommentSize: 32
  maxContractCommentSize: 32

  rewardDefault: 50
  rewardHalvingInterval: (210000 / 2) # blocks

  maxSupply: 21 * 1000000
  blockInterval: (60 * 5) # 5 mins

  difficultyDefault: 10
  difficultyAdjustmentInterval: (2016 / 2) # blocks
}

configStaging = {
  staging: true
  blockInterval: 30 # seconds
  difficultyAdjustmentInterval: 5
}

if vers.info().staging or env.STAGING
  config[k] = v for k,v of configStaging

config.genesisBlock = {
  _id: 0
  blockchain: config.versionInt
  transactions: []
  hash_previous: '0000000000000000000000000000000000000000000000000000000000000000'
  hash_merkle: ''
  difficulty: config.difficultyDefault
  nonce: 0
  hash: '0000000000000000000000000000000000000000000000000000000000000000'
  ctime: 0
  comment: 'we will craft citadels in the clouds or bury vaults within the ashes.'
}

if !module.parent
  console.log JSON.stringify config, null, 2

module.exports = config

