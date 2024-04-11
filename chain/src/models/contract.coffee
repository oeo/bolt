config = require './../config'

Blockchain = require './blockchain'
{Transaction,TransactionSchema} = require './transaction'

Wallet = require './../lib/wallet'

{
  time,
  createHash,
  indentedJSON,
  isObject,
} = require './../lib/helpers'

ContractSchema = new mongoose.Schema({

  blockchain: {
    type: String
    ref: 'Blockchain'
    default: config.version
  }

  address: {
    type: String
    required: true
    unique: true
    default: -> (new Wallet({

    }).address)
  }

  code: {
    type: String
    required: true
  }

  state: {
    type: mongoose.Schema.Types.Mixed
    default: {}
  }

  comment: {
    type: String
    default: null
    maxLength: config.maxContractCommentSize
  }

  ctime: {
    type: Number
    default: -> time()
  }

},{ versionKey:false, strict:true })

ContractSchema.pre 'save', (next) ->
  next()

ContractSchema.methods.log = (x...) ->
  x.unshift('contract-' + @_id.blue)
  log x...

ContractSchema.methods.getBalance = ->
  blockchain = await Blockchain.findOne _id:@blockchain
  balance = await blockchain.addressBalance(@address)
  return balance

ContractSchema.methods.executeFunction = (fnName, args) ->
  # 2. Call the specified function with the provided arguments
  # 3. Update the contract's state based on the function's result
  # 4. Save the updated state to the database 
  return true

Contract = mongoose.model 'Contract', ContractSchema
module.exports = Contract

