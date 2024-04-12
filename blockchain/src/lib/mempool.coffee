# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
Redis = require 'ioredis'
config = require './../config'

{ Transaction } = require './../models/transaction'

class Mempool
  constructor: (blockchainId) ->
    @client = new Redis(config.storage.redis)

    @prefix = _.compact([
      config.storage.redisPrefix
      blockchainId
    ]).join(':')

    @key = @prefix + ':mempool'

  # Add a transaction to the mempool
  addTransaction: (transaction) ->
    @client.zadd @key, transaction.fee, transaction._id

  # Remove a transaction from the mempool
  removeTransaction: (transactionId) ->
    @client.zrem @key, transactionId

  # Update the fee of a transaction in the mempool
  updateTransactionFee: (transactionId, newFee) ->
    @client.zadd @key, 'XX', newFee, transactionId

  # Retrieve transactions from the mempool in sorted order (highest fee first)
  getTransactions: (limit = 10) ->
    transactionIds = await @client.zrevrange @key, 0, limit - 1
    
    transactions = []
    for transactionId in transactionIds
      transactionData = await @client.hgetall @prefix + ':' + transactionId
      transaction = new Transaction(transactionData)
      if transaction.isValid()
        transactions.push transaction

    return transactions

  # Get the number of transactions in the mempool
  getTransactionCount: ->
    count = await @client.zcard @key
    return count

  # Clear all transactions from the mempool
  clear: ->
    redis.del @key

  # Process a block and remove its transactions from the mempool
  processBlock: (block) ->
    for transaction in block.transactions
      @removeTransaction @prefix + ':' + transaction._id

  # Retrieve the highest fee transactions that fit within the max block size
  getHighestFeeTransactions: (limit, maxSize) ->
    transactionIds = await @client.zrevrange @key, 0, -1
    
    transactions = []
    currentSize = 0
    
    for transactionId in transactionIds
      transactionData = await @client.hgetall @prefix + ':' + transactionId
      transaction = new Transaction(transactionData)
      
      if transaction.isValid()
        transactionSize = JSON.stringify(transaction).length
        if currentSize + transactionSize <= maxSize and transactions.length < limit
          transactions.push transaction
          currentSize += transactionSize
        else
          break
    
    return transactions

  # Retrieve all pending transactions from the mempool
  getPendingTransactions: ->
    transactionIds = await @client.zrange @key, 0, -1
    
    transactions = []

    for transactionId in transactionIds
      transactionData = await @client.hgetall @prefix + ':' + transactionId
      transaction = new Transaction(transactionData)
      if transaction.isValid()
        transactions.push transaction

    return transactions

module.exports = Mempool

