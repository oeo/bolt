# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
{ log } = console

EventEmitter2 = require('eventemitter2')

{ createLibp2p } = await import('libp2p')
{ noise } = await import('@chainsafe/libp2p-noise')
{ yamux } = await import('@chainsafe/libp2p-yamux')
{ bootstrap } = await import('@libp2p/bootstrap')
{ identify } = await import('@libp2p/identify')
{ kadDHT } = await import('@libp2p/kad-dht')
{ mplex } = await import('@libp2p/mplex')
{ tcp } = await import('@libp2p/tcp')
{ gossipsub } = await import('@chainsafe/libp2p-gossipsub')

class PeerNode extends EventEmitter2
  constructor: (options = {}) ->
    super()
    @peers = new Set()
    @options = {
      bootstrapPeers: [
        '/ip4/104.131.131.82/tcp/4001/p2p/QmaCpDMGvV2BGHeYERUEnRQAwe3N8SzbUtfsmvsqQLuvuJ'
        '/dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN'
        '/dnsaddr/bootstrap.libp2p.io/p2p/QmbLHAnMoJPWSCR5Zhtx6BHJX9KiKNN6tpvbUcqanj75Nb'
        '/dnsaddr/bootstrap.libp2p.io/p2p/QmZa1sAxajnQjVM8WjWXoMbmPd7NsWhfKsPkErzpm9wGkp'
        '/dnsaddr/bootstrap.libp2p.io/p2p/QmQCU2EcMqAqQPR2i9bChDtGNJchTbq5TbXJJ16u19uLTa'
        '/dnsaddr/bootstrap.libp2p.io/p2p/QmcZf59bWwK5XFi76CZX8cbJ4BhTzzA3gU1ZjYZcYW3dwt'
      ]
      pubsubConfig:
        emitSelf: true
        gossipIncoming: true

      ...options
    }

  start: ->
    @node = await createLibp2p
      addresses: listen: ['/ip4/0.0.0.0/tcp/0']
      transports: [tcp()]
      streamMuxers: [yamux(), mplex()]
      connectionEncryption: [noise()]
      peerDiscovery: [
        bootstrap list: @options.bootstrapPeers
      ]
      services:
        kadDHT: kadDHT()
        identify: identify()
        pubsub: gossipsub(@options.pubsubConfig)

    @node.addEventListener 'peer:connect', (evt) =>
      @peers.add evt.detail.toString()
      @emit 'peer', evt.detail.toString()

    @node.addEventListener 'peer:disconnect', (evt) =>
      @peers.delete evt.detail.toString()
      @emit 'peer_disconnect', evt.detail.toString()

    @node.services.pubsub.addEventListener 'message', (message) =>
      topic = message.detail.topic
      data = new TextDecoder().decode(message.detail.data)
      @emit 'message', { topic, data }

    await @node.start()
    @emit 'node_start'

  stop: ->
    await @node.stop()
    @emit 'node_stop'

  pubsub: (topic) ->
    @node.services.pubsub.subscribe topic
    emitter = new EventEmitter2()
    emitter.publish = (data) =>
      encodedMessage = new TextEncoder().encode(data)
      @node.services.pubsub.publish topic, encodedMessage
    return emitter

  getPeers: ->
    Array.from(@peers)

module.exports = PeerNode

if !module.parent
  p2p = new PeerNode()
  await p2p.start()

  chat = p2p.pubsub('chat')
  chat.on 'message', (data) ->
    log /chat data/, data

  blocks = p2p.pubsub('blocks')
  blocks.on 'message', (data) ->
    log /block message/, data

  p2p.on 'message', ({ topic, data }) ->
    log /received message on topic #{topic}:/, data

  chat.publish('Hello from chat topic!')
  blocks.publish('Hello from blocks topic!')

  await new Promise (resolve) -> setTimeout resolve, 5000
  log /connected peers:/, p2p.getPeers()

