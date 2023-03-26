config = require './../config'
Peer = require 'peer'

class P2P
  constructor: (blockchain) ->
    @blockchain = blockchain
    @peers = []
    @peerServer = null

  init: (port) ->
    @initPeerServer(port)
    @initMessageHandlers()

  initPeerServer: (port) ->
    @peerServer = new Peer({port})
    @peerServer.on 'connection', (conn) =>
      @peers.push(conn)
      console.log "New peer connected: #{conn.peer}"

  initMessageHandlers: () ->
    @peerServer.on 'connection', (conn) =>
      conn.on 'data', (data) =>
        message = JSON.parse(data)
        switch message.type
          when 'query_latest_block' then @sendLatestBlock(conn)
          when 'query_blockchain' then @sendBlockchain(conn)
          when 'response_blockchain' then @handleBlockchainResponse(message.data)

  # Send the latest block to a peer
  sendLatestBlock: (conn) ->
    latestBlock = @blockchain.getLatestBlock()
    conn.send JSON.stringify({type: 'response_latest_block', data: latestBlock})

  # Send the entire blockchain to a peer
  sendBlockchain: (conn) ->
    conn.send JSON.stringify({type: 'response_blockchain', data: @blockchain.blocks})

  # Connect to a new peer using their PeerJS ID
  connectToPeer: (peerId) ->
    conn = @peerServer.connect(peerId)
    conn.on 'open', () =>
      @peers.push(conn)
      console.log "Connected to peer: #{conn.peer}"
      @initMessageHandlers()

  # Broadcast a new block to all connected peers
  broadcastNewBlock: (block) ->
    for conn in @peers
      conn.send JSON.stringify({type: 'response_latest_block', data: block})

  # Request the latest block from all connected peers
  queryLatestBlock: () ->
    for conn in @peers
      conn.send JSON.stringify({type: 'query_latest_block'})

  # Request the entire blockchain from all connected peers
  queryBlockchain: () ->
    for conn in @peers
      conn.send JSON.stringify({type: 'query_blockchain'})

  # Handle a received blockchain and synchronize with the local blockchain
  handleBlockchainResponse: (receivedBlocks) ->
    # Check the received blockchain for validity
    isValid = @blockchain.isValidChain(receivedBlocks)

    if isValid
      localBlocks = @blockchain.blocks
      # Replace the local blockchain if the received blockchain is longer
      if receivedBlocks.length > localBlocks.length
        console.log "Received blockchain is longer, replacing local blockchain"
        @blockchain.replaceChain(receivedBlocks)
    else
      console.log "Received invalid blockchain"

module.exports = P2P
