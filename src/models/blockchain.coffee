config = require './../config'

Block = require './block'
{Transaction,TransactionSchema} = require './transaction'

{
  median,
  calculateBlockReward,
  calculateBlockDifficulty,
} = require './../lib/helpers'

{
  time,
  sha256,
  indentedJSON,
  isObject,
} = require './../lib/helpers'

BlockchainSchema = new mongoose.Schema({

  _id: {
    type: String
    required: true
    default: config.version
  }

  default: {
    type: Boolean
    default: false 
  }

  miningReward: {
    type: Number
    default: config.rewardDefault
  }

  difficulty: {
    type: Number
    default: config.difficultyDefault
  }

  minFee: {
    type: Number
    default: config.minFee
  }

  mempool: [
    TransactionSchema
  ]

  height: {type:Number,default:0},

  time_last_block: {type:Number,default:0}

  ctime: {type:Number,default:time()}

},{versionKey:false,strict:true})

BlockchainSchema.post 'save', (doc) ->
  eve.emit 'blockchain_updated', {
    blockchain: doc.id,
    height: doc.height
  }

BlockchainSchema.methods.log = (x...) ->
  x.unshift(@_id.blue)
  log x... 

BlockchainSchema.methods.sync = ->
  exists = await Blockchain.findOne _id:@_id
  if !exists then await @save()

  genesisExists = await Block.findOne {
    _id: 0
    blockchain: @_id
  }

  return @ if !genesisExists
  return @ 

BlockchainSchema.methods.getLastBlock = (height=false) ->
  b = await Block
    .findOne({blockchain:@_id})
    .sort({_id:-1})
    .limit(1)

  if !b
    if height then return 0
    return null

  if height then return b._id
  return b

# render the next block to be mined
BlockchainSchema.methods.nextBlock = (minerWallet) ->
  lastBlock = await @getLastBlock()
  lastHeight = lastBlock?._id ? 0

  transactions = []

  rewardTransaction = new Transaction {
    to: minerWallet.address 
    from: null
    fee: 0
    amount: await calculateBlockReward(lastHeight + 1)
    comment: 'block_reward'
    publicKey: minerWallet.publicKey 
  }

  mempool = (_.sortBy @mempool, (x) -> -x.fee)

  maxSize = config.maxBlockSize
  maxTxns = config.maxTransactionsPerBlock

  if mempool?.length
    for transaction in mempool
      t = new Transaction(transaction) 
      transactions.push t

      break if transactions.length > maxTxns

  transactions.unshift(rewardTransaction) 

  if lastBlock
    newBlock = new Block {
      _id: lastHeight + 1 
      blockchain: @_id
      transactions: transactions
      comment: null
      hash: null
      hash_previous: lastBlock.hash
      difficulty: await calculateBlockDifficulty(@_id, lastHeight + 1) 
    }

  else
    genesis = _.clone(config.genesisBlock) 
    newBlock = new Block(genesis)

  return newBlock

BlockchainSchema.methods.query = (x...) ->
  await db.Blocks.find(x...)

BlockchainSchema.methods.addressBalance = (address,includeMempool=false) ->
  items = await Block.find({
    blockchain: @_id
    $or: [
      { 'transactions.to': address }
      { 'transactions.from': address }
    ]
  },{transactions:1}).sort({_id:1})

  balance = 0

  for x in items
    for t in x.transactions
      if t.to is address
        balance += t.amount
      if t.from is address
        balance -= (t.amount - t.fee)

  if !includeMempool then return balance

  result = {}
  result.onChain = balance
  result.mempoolCredit = 0
  result.mempoolDebt = 0
  
  for t in @mempool
    if t.to is address
      result.mempoolCredit += t.amount
    if t.from is address
      result.mempoolDebt -= (t.amount - t.fee)

  result.balanceCalculated = 
    (result.onChain + result.mempoolCredit - result.mempoolDebt)

  return result


##
Blockchain = mongoose.model 'Blockchain', BlockchainSchema 
module.exports = Blockchain
