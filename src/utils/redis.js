const log = require('./log')
const config = require('./../config')

const Redis = require('ioredis')
const redis = new Redis(config.redis)

redis.on('error', (err) => {
  log.error(err)
})

module.exports = { 
  redis,
} 
