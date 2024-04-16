# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
config = require './../config'

L = (require './logger.coffee').L

Block = require './../models/block'
{ Transaction } = require './../models/transaction'

Mempool = require './mempool'

{
  median,
  calculateBlockReward,
  calculateBlockDifficulty,
  time,
} = require './helpers'

class Blockchain

  constructor: (options = {}) ->
    @_id = config.versionInt

  init: ->
    genesisExists = await Block.findOne(_id:0)

    if !genesisExists
      L 'creating genesis block', config.genesisBlock
      genesisBlock = new Block(config.genesisBlock)
      await genesisBlock.save()

    return @

  validate: ->
    blocks = await Block.find().sort(_id: 1)
    for block, index in blocks
      if index is 0
        if !(await block.isValid())
          throw new Error 'invalid genesis block'
      else
        prevBlock = blocks[index - 1]
        if prevBlock
          if !(await block.isValid({ prevBlock }))
            try
              await block.tryValidate({ prevBlock })
            catch e
              throw e
            throw new Error 'invalid block'

    return true

  addTransaction: (opt = {}) ->
    txnObj = new Transaction(opt)
    return txnObj.toJSON()

  nextBlock: (minerWallet) ->
    lastBlock = await @getLastBlock()
    lastHeight = lastBlock?._id or 0

    if !lastBlock
      throw new Error '`lastBlock` not found (no genesisBlock)'

    rewardTransaction = new Transaction {
      to: minerWallet.address
      from: null
      fee: 0
      amount: (await calculateBlockReward(lastHeight + 1))
      comment: 'block_reward'
      publicKey: minerWallet.publicKey
    }

    rewardTransaction = minerWallet.signTransaction(rewardTransaction)

    transactions = [rewardTransaction]

    # @todo: add transactions from mempool
    # ...

    newBlock = new Block {
      _id: lastHeight + 1
      blockchain: @_id
      transactions: transactions
      comment: null
      hash: null
      hash_previous: lastBlock.hash
      difficulty: await calculateBlockDifficulty(lastHeight + 1)
    }

    return newBlock

  getLastBlock: ->
    lastBlock = await Block.findOne().sort(_id:-1)
    lastBlock

  getBlock: (height) ->
    block = await Block.findOne(_id: height)
    block

  getTransactionsByAddress: (address) ->
    blocks = await Block.find(
      $or: [
        { 'transactions.from': address }
        { 'transactions.to': address }
      ]
    )

    transactions = []

    for block in blocks
      for transaction in block.transactions
        if transaction.from is address or transaction.to is address
          transactions.push(transaction)

    return transactions

  getBalance: (address) ->
    transactions = await @getTransactionsByAddress(address)

    balance = 0
    for transaction in transactions
      if transaction.to is address
        balance += transaction.amount
      if transaction.from is address
        balance -= transaction.amount + transaction.fee

    return balance

module.exports = Blockchain

if !module.parent
  b = new Blockchain()

  await b.init()
  await b.validate()

  log /ok/

