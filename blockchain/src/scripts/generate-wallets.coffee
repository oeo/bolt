#!/usr/bin/env coffee
require './../lib/globals'
config = require './../config'

Wallet = require './../lib/wallet'

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

for x in names
  json = new Wallet().toJSON()
  json.name = x
  wallets.push json

log JSON.stringify(wallets,null,2)

