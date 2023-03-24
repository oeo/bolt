global.log = console.log
global._ = require 'lodash'

module.exports = config = {
  version: '1.0' 
  algo: 'scrypt'
  blockInterval: 60 * 10 # seconds 
  maxBlockSize: 1024 * 1024 # bytes 
  maxTransactionsPerBlock: 4000
  maxTransactionCommentSize: 32
  maxBlockCommentSize: 80 
  initialReward: 50
  initialDifficulty: (initialDifficulty = 1000)
  minFee: 0.0001
  rewardHalvingInterval: 210000 # blocks
  difficultyAdjustmentInterval: 2016 # blocks
  confirmations: 6
  genesisBlock: {
    transactions: []
    hash_previous: '0000000000000000000000000000000000000000000000000000000000000000'
    difficulty: initialDifficulty 
    comment: 'genesis'
  }
  storage: {
    mongo: 'mongodb://127.0.0.1:27017/test9'
  }
}
