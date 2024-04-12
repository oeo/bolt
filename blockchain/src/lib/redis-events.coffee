# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
Redis = require 'ioredis'
{ EventEmitter } = require 'events'

class DistributedEventEmitter extends EventEmitter
  constructor: (redisOptions) ->
    super()

    @redisSubscriber = new Redis(redisOptions)
    @redisPublisher = new Redis(redisOptions)

    # Subscribe to a channel called 'events'
    @redisSubscriber.subscribe 'events'

    # Listen for messages on the 'events' channel
    @redisSubscriber.on 'message', (channel, message) =>
      if channel is 'events'
        { event, data } = JSON.parse message
        super.emit event, data

  # Override the default emit method to publish messages to Redis
  emit: (event, data) ->
    message = JSON.stringify { event, data }
    @redisPublisher.publish 'events', message

module.exports = DistributedEventEmitter

