# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
Swarm = require 'discovery-swarm'
crypto = require 'crypto'

DEFAULT_OPTS = {
  dns: {
    server: [
      'discovery1.datprotocol.com'
      'discovery2.datprotocol.com'
    ]
    domain: 'dat.local'
  }
  dht: {
    bootstrap: [
      'bootstrap1.datprotocol.com:6881'
      'bootstrap2.datprotocol.com:6881'
      'bootstrap3.datprotocol.com:6881'
      'bootstrap4.datprotocol.com:6881'
    ]
  }
}

swarmConfig = (opts) -> Object.assign({}, DEFAULT_OPTS, opts)

class Network
  constructor: (@topic, @id = null) ->
    if !@id
      @id = crypto.randomBytes(32)

    config = swarmConfig({
      id: @id
    })

    @swarm = Swarm(config)
    @peers = []

  start: ->
    @swarm.join(@topic)

    @swarm.on 'connection', (conn, info) =>
      console.log 'New peer connection!', info
      @peers.push(conn)

      console.log "Connected to peer: #{info.id.toString('hex')}"

      conn.on 'data', (data) =>
        @handleCommand data, conn

      conn.on 'close', =>
        console.log "Connection closed: #{info.id.toString('hex')}"

        index = @peers.indexOf(conn)

        if index isnt -1
          @peers.splice(index, 1)

      conn.on 'error', (err) =>
        console.error "Connection error: #{err.message}"

  handleCommand: (data, conn) ->
    try
      message = JSON.parse data

      switch message.cmd
        when 'ping'
          response = JSON.stringify({ cmd: 'pong' })
          conn.write response

        when 'customCommand'
          console.log 'Received custom command:', message.data

    catch error
      console.error 'Error handling command:', error

  broadcast: (message) ->
    for conn in @peers
      if conn.writable
        conn.write JSON.stringify(message)
      else
        console.log 'Connection is not writable.'

#
# usage
#

# Create and start the network
network = new Network('bolt')
network.start()

# Keep-alive mechanism
setInterval(() ->
  network.broadcast({ cmd: 'ping' })
  console.log /peers/, network.peers.length
, 5000)

# Send a custom command
setTimeout(() ->
  customData = { cmd: 'customCommand', data: 'Hello, P2P World!' }
  network.broadcast(customData)
, 5000) # Wait 5 seconds before sending

