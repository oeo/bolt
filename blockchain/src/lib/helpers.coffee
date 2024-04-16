config = require './../config'

util = require 'util'
uuid = require 'uuid'
crypto = require 'crypto'
base_x = require 'base-x'

BASE_ALPHABETS = {
  BASE_36: '123456789abcdefghijklmnopqrstuvwxyz'
  BASE_58: '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
}

# m/84h/779h/0h/0h
# https://github.com/satoshilabs/slips/blob/master/slip-0044.md
DERIVATION_DEFAULT = {
  purpose: 84
  coinType: 779
  account: 0
  change: 0
  index: 0
}

{ scrypt } = require('@noble/hashes/scrypt')
bolthash = require __dirname + '/../../../bolthash/nodejs'

module.exports = helpers = lib = {
  DERIVATION_DEFAULT
  BASE_ALPHABETS
  BASE_CLIENTS: {}
}

for k,v of lib.BASE_ALPHABETS
  lib.BASE_CLIENTS[k] = base_x(v)

lib.base_operation = (operation = 'encode', model = 58, data) -> (
  if operation !in ['encode', 'decode']
    throw new Error 'Invalid base operation. Valid: [encode, decode]'

  try model = model.toString().toUpperCase()

  client = lib.BASE_CLIENTS[model] ? lib.BASE_CLIENTS["BASE_#{model}"]

  if !client
    throw new Error "Invalid base model. Valid: #{_.keys(lib.BASE_CLIENTS).join(', ')}"

  client[operation](data)
)

lib.base_encode = (model, data) ->
  if !data and model
    data = model
    model = 58

  buffer = Buffer.from(data,'hex')
  data = new Uint8Array(buffer)

  lib.base_operation 'encode', model, data

lib.base_decode = (model, data) ->
  if !data and model
    data = model
    model = 58

  data = lib.base_operation 'decode', model, data

lib.getVersion = ->
  { version } = require __dirname + '/../../package.json'
  [major, minor, patch] = _.map version.split('.'), (x) -> +x
  return { major, minor, patch }

lib.getVersionByte = ->
  { major, minor, patch } = getVersion()
  if major < 0 or major > 15 or minor < 0 or minor > 15
    throw new Error('Major and minor versions must be between 0 and 15')
  return (major << 4) + minor

lib.sleep = (ms) -> new Promise (resolve, reject) ->
  setTimeout resolve, ms

lib.uuid = uuid.v4

lib.time = -> _.floor(new Date().getTime() / 1000)

lib.timeBucket = (seconds) ->
  now = Math.floor(new Date().getTime() / 1000)
  bucketSize = seconds
  bucket = Math.floor(now / bucketSize) * bucketSize
  return bucket

lib.buildDerivationPath = (opt = {
  account: 0
  change: 0
  index: 0
}) ->
  defaults = DERIVATION_DEFAULT

  for k,v of defaults
    opt[k] ?= v

  parts = [
    'm'
    "#{opt.purpose}h"
    "#{opt.coinType}h"
    "#{opt.account}h"
    "#{opt.change}h"
    "#{opt.index}h"
  ]

  return parts.join '/'

# Adjusted sha256 function to optionally return a Buffer
lib.sha256 = (val, returnAsBuffer = false) ->
  digestFormat = if returnAsBuffer then 'buffer' else 'hex'
  crypto.createHash('sha256').update(val).digest(digestFormat)

lib.createHash = (val, opt = {}) ->
  defaults = { type: 'sha' }

  for k, v of defaults
    opt[k] ?= v

  if opt.type in ['sha', 'sha256']
    return lib.sha256(val)

  if opt.type is 'scrypt'
    hashUintArr = scrypt(val, '', { N: 1024, r: 8, p: 1, dkLen: 32 })
    return lib.createHash(Buffer.from(hashUintArr).toString('hex'), { type: 'sha' })

  if opt.type is 'bolthash'
    return bolthash(val)

  throw new Error 'Invalid `opt.type`'

lib._confirm = (question, defaultResponse='Y', cb) ->
  readline = require 'readline'

  rl = readline.createInterface process.stdin, process.stdout

  if typeof(defaultResponse) is 'string'
    defaultResponse = defaultResponse.toLowerCase().substr(0,1)
  else if typeof(defaultResponse) is 'boolean'
    defaultResponse = 'n'
    if defaultResponse then defaultResponse = 'y'

  if defaultResponse is 'y'
    defaultBool = true
    responseMarkup = "[Y/n]"
  else
    defaultBool = false
    responseMarkup = "[y/N]"

  questionStr = [
    question,
    responseMarkup
  ].join(' ')

  L questionStr

  rl.question '', (answer) ->
    validYes = ['y','yes']

    if defaultBool
      validYes = validYes.concat ['',null]

    if answer?.trim?().toLowerCase() in validYes
      answer = true
    else
      answer = false

    rl.close()
    return cb null, answer

lib.confirm = util.promisify(lib._confirm)

lib.indentedJSON = (jsonString,level=2,returnPrefix=false) ->
  prefix = (" " for x in [1..level]).join('')
  if returnPrefix then return prefix
  json = JSON.parse(jsonString)
  formattedJson = JSON.stringify(json, null, 2)
  indentedJson = formattedJson.replace(/^/gm, prefix)
  return indentedJson

lib.isObject = (variable) ->
  return Object.prototype.toString.call(variable) is '[object Object]'

lib.prettyLog = (prefix,x...) ->
  x2 = []
  for item in x
    x2.push '\n'
    x2.push item
  log(prefix.yellow,...x2)

lib.median = (numbers) ->
  numbers = (numbers.filter (n) -> n != null).sort (a, b) -> a - b
  middle = Math.floor numbers.length / 2

  if numbers.length % 2
    numbers[middle]
  else
    (numbers[middle - 1] + numbers[middle]) / 2.0

lib.calculateBlockReward = (blockHeight = 0) ->
  rewardHalvingInterval = config.rewardHalvingInterval
  halvings = _.floor(blockHeight / rewardHalvingInterval)
  reward = config.rewardDefault / (2 ** halvings)
  return reward

lib.calculateBlockDifficulty = (blockHeight = 0) ->
  Block = require './../models/block'

  getBlock = (query = null) ->
    if !query
      r = await Block.findOne().sort({_id:-1})
      return r
    r = await Block.findOne(query)
    return r

  # Check if we should adjust difficulty at this block height
  if blockHeight < config.difficultyAdjustmentInterval
    return config.difficultyDefault

  if blockHeight % config.difficultyAdjustmentInterval isnt 0
    lastBlock = await getBlock({_id: blockHeight - 1})
    return lastBlock.difficulty

  # Fetch the start and end blocks for the period
  startBlock = await getBlock({_id: blockHeight - config.difficultyAdjustmentInterval})
  endBlock = await getBlock({_id: blockHeight - 1})

  actualTimespan = endBlock.ctime - startBlock.ctime
  targetTimespan = config.blockInterval * config.difficultyAdjustmentInterval

  # Cap the timespan to prevent extreme difficulty adjustments
  actualTimespan = Math.max(actualTimespan, targetTimespan / 4)
  actualTimespan = Math.min(actualTimespan, targetTimespan * 4)

  # Calculate new difficulty based on timespan differences
  newDifficulty = endBlock.difficulty * (targetTimespan / actualTimespan)
  maxAdjustmentFactor = 4

  # Ensure that difficulty changes are within the allowed range
  newDifficulty = Math.max(newDifficulty, endBlock.difficulty / maxAdjustmentFactor)
  newDifficulty = Math.min(newDifficulty, endBlock.difficulty * maxAdjustmentFactor)

  # Round and log the new difficulty
  newDifficulty = Math.round(newDifficulty)

  return newDifficulty


