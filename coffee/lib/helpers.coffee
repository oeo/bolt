config = require './../config'

util = require 'util'

crypto = require 'crypto'
readline = require 'readline'

time = -> _.floor(new Date().getTime() / 1000) 

timeBucket = (seconds) ->
  now = Math.floor(new Date().getTime() / 1000)
  bucketSize = seconds
  bucket = Math.floor(now / bucketSize) * bucketSize
  return bucket

sha256 = (val) ->
  crypto.createHash('sha256')
    .update(val)
    .digest('hex')

_confirm = (question, defaultResponse='Y', cb) ->
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

confirm = util.promisify(_confirm)

indentedJSON = (jsonString,level=2,returnPrefix=false) ->
  prefix = (" " for x in [1..level]).join('')
  if returnPrefix then return prefix
  json = JSON.parse(jsonString)
  formattedJson = JSON.stringify(json, null, 2)
  indentedJson = formattedJson.replace(/^/gm, prefix)
  return indentedJson

isObject = (variable) ->
  return Object.prototype.toString.call(variable) is '[object Object]'

prettyLog = (prefix,x...) ->
  x2 = []
  for item in x
    x2.push '\n' 
    x2.push item
  log(prefix.yellow,...x2)

median = (numbers) ->
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

calculateBlockReward = (blockHeight = 0) ->
  rewardHalvingInterval = config.rewardHalvingInterval
  halvings = _.floor(blockHeight / rewardHalvingInterval)
  reward = config.rewardDefault / (2 ** halvings)
  return reward

calculateBlockDifficulty = (blockchainId, blockHeight = 0) ->
  Block = require './../models/block'

  query = {
    blockchain: blockchainId 
  }

  if blockHeight
    query['_id'] = {
      $lte: blockHeight
    }

  diffBlocks = await Block 
    .find(query,{ctime:1,time_elapsed:1,difficulty:1})
    .sort(_id:-1)
    .limit(config.difficultyChangeBlockConsideration)
    .lean()

  if !diffBlocks.length
    return config.difficultyDefault

  currentDifficulty = _.first(diffBlocks)?.difficulty ? config.difficultyDefault

  averageElapsed = _.map diffBlocks, (x) -> x.time_elapsed
  averageElapsed = _.ceil median averageElapsed

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

module.exports = {
  time,
  timeBucket,
  sha256,
  confirm,
  isObject,
  indentedJSON,
  prettyLog,
  median,
  calculateBlockReward,
  calculateBlockDifficulty,
}
