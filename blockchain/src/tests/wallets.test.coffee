# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
process.env.TESTING = 1

config = require './../lib/globals'
Wallet = require './../lib/wallet'

assert = require 'assert'
after -> process.exit 0

names = """
  taky
  james
  john
  robert
  michael
  william
  david
  richard
  joseph
  thomas
  charles
  doug
  bob
  satoshi
"""

names = _.compact _.map names.trim().split('\n'), (x) -> x.trim()
wallets = []

describe 'wallets', ->

  it 'should generate 10 wallets', ->
    for x in names
      json = new Wallet().toJSON()
      json.name = x
      wallets.push json

    assert.equal names.length, wallets.length

