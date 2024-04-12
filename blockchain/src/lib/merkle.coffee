# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
config = require './globals'

crypto = require 'crypto'
{ createHash } = require './helpers'

module.exports = merkle_hash = (array) ->
  if !Array.isArray(array)
    throw new Error('Input must be an array')

  if array.length == 0
    return ''

  obj = {}

  for i in [0...array.length]
    hash = createHash(
      JSON.stringify(array[i]),
      { type: config.algo }
    )

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
      createHash(
        pair,
        { type: config.algo }
      )
    )

    keys = pairs
    values = hashes

  return values[0]

if !module.parent
  arr = [
    { to: 'bob', from: 'fred', amount: 20 }
    { to: 'fred', from: 'john', amount: 50 }
  ]

  console.log(merkle_hash(arr))

  arr2 = [
    { to: 'fred', from: 'john', amount: 50 }
    { to: 'bob', from: 'fred', amount: 20 }
  ]

  console.log(merkle_hash(arr2))

  # 2a2ceec2b1282aec6311e92f3c4c84695d5300425c6007ced370154375494b63
  # 2a2ceec2b1282aec6311e92f3c4c84695d5300425c6007ced370154375494b63

  exit 0

