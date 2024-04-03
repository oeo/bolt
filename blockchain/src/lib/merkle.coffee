crypto = require 'crypto'

module.exports = merkle_hash = (array) ->
  if !Array.isArray(array)
    throw new Error('Input must be an array')

  if array.length == 0
    return ''

  obj = {}
  for i in [0...array.length]
    hash = crypto.createHash('sha256')
                 .update(JSON.stringify(array[i]))
                 .digest('hex')
    obj[hash] = array[i]

  if Object.keys(obj).length == 1
    return Object.keys(obj)[0]

  keys = Object.keys(obj).sort()
  values = keys.map((key) -> obj[key])

  while keys.length > 1
    if keys.length % 2 != 0
      keys.push(keys[keys.length - 1])
      values.push(values[values.length - 1])

    pairs = []
    for i in [0...keys.length] by 2
      pair = [keys[i], keys[i + 1]].sort().join('')
      pairs.push(pair)

    hashes = pairs.map((pair) ->
      crypto.createHash('sha256').update(pair).digest('hex'))

    keys = pairs
    values = hashes

  return values[0]

if !module.parent
  arr = [
    {to:'bob',from:'fred',amount:20}
    {to:'fred',from:'john',amount:50}
  ]

  console.log(merkle_hash(arr))
