module.exports = {
  algo: 'scrypt',
  blockInterval: 60 * 10, // in seconds
  maxBlockSize: 1024 * 1024, // in bytes
  maxTransactionsPerBlock: 1000,
  maxTransactionMemoSize: 255,
  maxBlockCommentSize: 255,
  initialReward: 50,
  initialDifficulty: 1,
  minFee: 0.0001,
  rewardReductionInterval: 2100000, // in blocks,
  difficultyAdjustmentInterval: 100, // in blocks
  confirmations: 6,
  genesisData: {
    ctime: 1679618522,
    transactions: [],
    previousHash: '0000000000000000000000000000000000000000000000000000000000000000',
    nonce: 0,
    difficulty: 1,
    comment: 'genesis',
  },
  redis: {
    host: 'localhost',
    port: 6379,
  },
}