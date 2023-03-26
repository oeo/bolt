config = require './../config'

util = require 'util'

crypto = require 'crypto'
readline = require 'readline'

time = (divis = false) -> 
  num = 1000
  if divis = 'ms' then num = 1 
  Math.floor(Date.now() / num) 

timeBucket = (seconds) ->
  now = Math.floor(Date.now() / 1000)  # Get the current Unix epoch time in seconds
  bucketSize = seconds  # Set the bucket size to 60 seconds

  bucket = Math.floor(now / bucketSize) * bucketSize  # Calculate the current time bucket

  return bucket

sha256 = (val) ->
  return crypto.createHash('sha256').update(val).digest('hex')

_confirm = (question,defaultResponse='Y',cb) ->
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

module.exports = {
  time,
  timeBucket,
  sha256,
  confirm,
  isObject,
  indentedJSON,
  prettyLog,
}
