module.exports = {
  algo: 'scrypt',
  blockInterval: 10, // in seconds
  maxBlockSize: 1024 * 1024, // in bytes
  maxTransactionsPerBlock: 1000,
  maxTransactionMemoSize: 255,
  maxBlockCommentSize: 255,
  initialReward: 50,
  initialDifficulty: 1,
  minFee: 0.0001,
  rewardReductionInterval: 210000, // in blocks
  difficultyAdjustmentInterval: 2016, // in blocks
  confirmations: 6,
  genesisData: {
    timestamp: 1634572800, // October 19, 2021 12:00:00 AM UTC
    transactions: [],
    previousHash: '0000000000000000000000000000000000000000000000000000000000000000',
    nonce: 0,
    difficulty: 1,
    comment: 'GENESIS'
  }
}