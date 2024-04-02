process.noDeprecation = true

module.exports = config = require './../config'

global.log ?= console.log
global.env ?= process.env
global.exit ?= process.exit
global._ ?= require 'lodash'

require 'colors'

global.mongoose ?= require 'mongoose'
await mongoose.connect config.storage.mongo

reve = require './redis-events'
global.eve ?= new reve(config.storage.redis)

