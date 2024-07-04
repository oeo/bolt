process.noDeprecation = true

module.exports = config = require './../config'

colors = require 'colors'
global.colors ?= colors

global.log ?= console.log
global.env ?= process.env
global.exit ?= process.exit

global.L = (require './logger.coffee').L
global._ ?= require 'lodash'

global.version = (require './version.coffee')

if !global.mongoose
  global.mongoose ?= require 'mongoose'
  mongoose.connect config.storage.mongo

if !global.redis
  Redis = require 'ioredis'
  global.redis ?= new Redis(config.storage.redis)

if !global.eve
  reve = require './redis-events'
  global.eve ?= new reve(config.storage.redis)

# node identity
global.identity ?= (require './identity.coffee')

