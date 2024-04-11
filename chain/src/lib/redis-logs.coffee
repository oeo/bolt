# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
Redis = require 'ioredis'

class CappedLogStorage
  constructor: (redisOptions, prefix, maxSize = 10) ->
    @client = new Redis(redisOptions)
    @prefix = prefix
    @maxSize = maxSize

  addLog: (log) ->
    key = "#{@prefix}:logs"
    @client.multi()
      .rpush(key, JSON.stringify(log))
      .ltrim(key, -@maxSize, -1)
      .exec()

  getLogs: ->
    key = "#{@prefix}:logs"
    @client.lrange key, 0, -1

# Usage example
redisOptions =
  host: '127.0.0.1'
  port: 6379
  db: 0

logStorage = new CappedLogStorage(redisOptions, 'myApp', 100)

# Adding a log entry
logStorage.addLog { date: new Date().toISOString(), message: 'Log message' }

# Retrieving log entries
logStorage.getLogs().then (logs) ->
  console.log logs.map(JSON.parse)

