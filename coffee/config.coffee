global.log = console.log
global._ = require 'lodash'
global.eve = new (require('events')).EventEmitter()

require 'colors'

VERSION = 'furious-fish'
STAGING = true

config = {
  version: VERSION 
  staging: false
  bip32RootPath: "m/44'/0'/0'/0"
  algo: 'scrypt'
  blockInterval: 60 * 10 # seconds 
  maxBlockSize: 1024 * 1024 # bytes 
  maxTransactionsPerBlock: 4000
  maxTransactionCommentSize: 32
  maxBlockCommentSize: 32
  initialReward: 50
  initialDifficulty: 1000
  minFee: 0.0001
  rewardHalvingInterval: 210000 # blocks
  difficultyAdjustmentInterval: 2016 # blocks 
  confirmations: 6
  storage: {
    mongo: 'mongodb://127.0.0.1:27017/prod-' + VERSION 
  }
  ports: {
    http: 12120
    p2p: 12121
  }
}

configStaging = {
  version: 'stage-' + config.version
  staging: true
  bip32RootPath: "m/44'/1'/0'/0"
  initialDifficulty: 100
  rewardHalvingInterval: 1000
  difficultyAdjustmentInterval: 100
  storage: { 
    mongo: 'mongodb://127.0.0.1:27017/stage-' + config.version
  }
}

if STAGING 
  config[k] = v for k,v of configStaging

config.genesisBlock = {
  _id: 0
  transactions: []
  hash_previous: '0000000000000000000000000000000000000000000000000000000000000000'
  difficulty: config.initialDifficulty 
  comment: 'genesis'
}

module.exports = config
