config = require './globals'

util = require 'util'
crypto = require 'crypto'

base_x = require 'base-x'

BASE_ALPHABETS = {
  BASE_36: '123456789abcdefghijklmnopqrstuvwxyz'
  BASE_58: '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
}

{ scrypt } = require('@noble/hashes/scrypt')
bolthash = require __dirname + '/../../../bolthash/nodejs'

helpers = lib = {
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

lib.sleep = (ms) -> new Promise (resolve, reject) ->
  setTimeout resolve, ms

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
  defaults = {
    purpose: config.derivation.purpose
    coinType: config.derivation.coinType
    account: config.derivation.account
    change: config.derivation.change
    index: config.derivation.index
  }

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
    return lib.createHash(Buffer.from(hashUintArr).toString('hex'), 'sha')

  if opt.type is 'bolthash'
    return bolthash val

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
  ].join(' ').magenta

  rl.question questionStr + ': ', (answer) ->
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
  if !numbers? or numbers.length == 0
    throw new Error("Input array must be non-empty")

  if numbers.length is 1 then return _.first(numbers)

  # Sort the numbers in ascending order
  sortedNumbers = numbers.slice().sort (a, b) -> a - b

  # Calculate the middle index of the sorted array
  middleIndex = Math.floor(sortedNumbers.length / 2)

  # If the length of the array is even, return the average of the two middle elements
  # Otherwise, return the middle element
  result =
    if sortedNumbers.length % 2 == 0
      (sortedNumbers[middleIndex - 1] + sortedNumbers[middleIndex]) / 2
    else
      sortedNumbers[middleIndex]

  return result

lib.calculateBlockReward = (blockHeight = 0) ->
  rewardHalvingInterval = config.rewardHalvingInterval
  halvings = _.floor(blockHeight / rewardHalvingInterval)
  reward = config.rewardDefault / (2 ** halvings)
  return reward

lib.calculateBlockDifficulty = (blockchainId, blockHeight = 0) ->
  Block = require './../models/block'

  query = {
    blockchain: blockchainId
  }

  if blockHeight
    query['_id'] = {
      $lte: blockHeight
    }

  diffBlocks = await Block
    .find(query,{ ctime: 1, time_elapsed: 1, difficulty: 1 })
    .sort(_id:-1)
    .limit(config.difficultyChangeBlockConsideration)
    .lean()

  if !diffBlocks.length
    return config.difficultyDefault

  currentDifficulty = _.first(diffBlocks)?.difficulty ? config.difficultyDefault

  averageElapsed = _.map diffBlocks, (x) -> x.time_elapsed
  averageElapsed = _.ceil lib.median averageElapsed

  if currentDifficulty < config.difficultyDefault
    currentDifficulty = config.difficultyDefault

  drastic = false

  if averageElapsed < config.blockInterval
    if averageElapsed < config.blockInterval / 2
      drastic = true

    if drastic
      currentDifficulty += (currentDifficulty * (config.difficultyChangePercentDrastic/100))
    else
      currentDifficulty += (currentDifficulty * (config.difficultyChangePercent/100))
  
  if averageElapsed > config.blockInterval
    if averageElapsed > config.blockInterval * 2
      drastic = true

    if drastic
      currentDifficulty -= (currentDifficulty * (config.difficultyChangePercentDrastic/100))
    else
      currentDifficulty -= (currentDifficulty * (config.difficultyChangePercent/100))

  return _.ceil(currentDifficulty)

module.exports = lib

