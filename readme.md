<p align="center">
  <img src="assets/logo-red-bg.svg" height="200">
</p>

bolt is a censorship-resistant, distributed proof-of-work blockchain. miners
are rewarded in bolt for solving blocks, the native currency of the chain.

- custom hashing function: designed to attempt to provide similar performance between cpu and gpu mining.
- native chain currency: bolt has its native currency for rewarding miners.
- proof of work: the blockchain is designed to inherit bitcoin's best characteristics.
  - automatic difficulty adjustments and target block times.
  - fixed supply cap and decreasing issuance of block rewards.
  - the chain can be configured to use bolt's custom hashing function, sha256 or scrypt.

### peer discovery

this project uses the [libp2p](https://libp2p.io/) library for peer-to-peer 
communication and peer discovery.

the main components involved in peer discovery are:

- bootstrap nodes: these are predefined nodes that act as initial entry points to the network.
- kad-dht: the kademlia distributed hash table (kad-dht) is used for efficient peer discovery and content routing. it allows nodes to find and connect to other nodes based on their node ids.
- identify protocol: the identify protocol is used to exchange node information between peers. when two nodes connect, they exchange their node ids, addresses, and other metadata using the identify protocol.
- gossipsub: gossipsub is a pubsub (publish-subscribe) protocol used for message propagation and peer discovery.

when a new node is started, it performs the following steps for peer discovery:

1. connects to the specified bootstrap nodes to join the network.
1. participates in the kad-dht to discover and connect to other peers based on their node ids.
1. exchanges node information with connected peers using the identify protocol.
1. subscribes to specified topics using gossipsub and starts receiving messages published by other nodes on those topics.
1. gossips about known peers and their subscribed topics to help other nodes discover and connect to them.


### fair distribution
when mainnet is launched anyone interested will be able to run a node and 
begin mining blocks and will be eligible for the block subsidy reward.

there will be no preallocated tokens of any kind, no airdrop of any kind,
and no fundraising or premine of any kind.

### @todo
- [x] enforce bolthash to produce sha256 like hex only outputs with same len
  - [x] rebuild node module and test
  - [x] rebuild cli tool and test
  - [ ] fix webasm export
- [ ] give node a keypair identifier unless already provided
- [ ] p2p
  - [ ] standardize message format
  - [ ] add a p2p chat for node runners (fun!)
  - [ ] p2p discovery
    - [x] utilize ipfs pubsub implementation
      [x] - lift the libp2p logic and write as service or wrap ipfs itself
- [ ] add concept block explorer (react)
- [ ] create standalone wallet (electron?/web?/browserext?)
- [ ] dockerize everything

### @eventual
- rust-based v8 smart contract executor
  - allows newcomers to write in a familiar syntax while maintaining strict execution and computation limits for miners
  - highly performant and circumvents nodejs' single-threaded nature

### license

mit license

permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "software"), to deal
in the software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the software, and to permit persons to whom the software is
furnished to do so, subject to the following conditions:

the above copyright notice and this permission notice shall be included in all
copies or substantial portions of the software.

the software is provided "as is", without warranty of any kind, express or
implied, including but not limited to the warranties of merchantability,
fitness for a particular purpose and noninfringement. in no event shall the
authors or copyright holders be liable for any claim, damages or other
liability, whether in an action of contract, tort or otherwise, arising from,
out of or in connection with the software or the use or other dealings in the
software.

