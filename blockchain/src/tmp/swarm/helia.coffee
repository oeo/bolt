# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
crypto = require 'crypto'
{ createHelia } = await import('helia')
{ createEd25519PeerId } = await import('@libp2p/peer-id-factory')

# Generate a new peer ID with a private key
peerId = await createEd25519PeerId()

# Configuration options
config =
  peerId: peerId
  listenAddresses: ['/ip4/0.0.0.0/tcp/0']
  announceAddresses: []
  bootstrapAddresses: [
    '/ip4/104.131.131.82/tcp/4001/p2p/QmaCpDMGvV2BGHeYERUEnRQAwe3N8SzbUtfsmvsqQLuvuJ'
    '/dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN'
  ]
  modules:
    bitswap: null

# Create a Helia node
node = await createHelia(config)

# Start the node
await node.start()

# Get the node's listening addresses
listeningAddresses = node.getMultiaddrs()

console.log "Node started with ID: #{node.peerId.toString()}"
console.log "Listening on addresses:"
console.log address.toString() for address in listeningAddresses

# Handle connection events
node.on 'peer:connect', (evt) ->
  console.log "Connected to peer: #{evt.remotePeer.toString()}"

# Handle disconnection events
node.on 'peer:disconnect', (evt) ->
  console.log "Disconnected from peer: #{evt.remotePeer.toString()}"

# Discover peers
discoveredPeers = await node.peerStore.peers()

console.log "Discovered peers:"
console.log peer.id.toString() for peer in discoveredPeers

# Stop the node when done
await node.stop()

