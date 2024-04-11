# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
{spawn, exec} = require 'child_process'
{EventEmitter} = require 'events'

class IPFSPubSub extends EventEmitter
  constructor: ->
    super()
    @checkAndStartDaemon()

  checkAndStartDaemon: ->
    exec 'ipfs config show', (error, stdout, stderr) =>
      if error or stderr
        console.error 'Error checking IPFS config:', error or stderr
        return
      unless stdout.includes '"Pubsub.Router": "gossipsub"'
        console.log 'Starting IPFS daemon with pubsub...'
        ipfsDaemon = spawn 'ipfs', [
          'daemon'
          '--enable-pubsub-experiment'
        ]
        ipfsDaemon.stdout.on 'data', (data) =>
          output = data.toString()
          console.log output
          if output.includes 'Daemon is ready'
            @subscribeToTopic()
      else
        @subscribeToTopic()

  subscribeToTopic: ->
    console.log 'Subscribing to my-topic...'
    ipfsSub = spawn 'ipfs', ['pubsub', 'sub', 'my-topic']
    ipfsSub.stdout.on 'data', (data) =>
      message = data.toString().trim()
      console.log 'Message received:', message
      @emit 'message', message
    ipfsSub.stderr.on 'data', (data) ->
      console.error 'Error subscribing to topic:', data.toString()

ipfsPubSub = new IPFSPubSub()
ipfsPubSub.on 'message', (message) ->
  console.log 'Event Emitted, Message:', message

