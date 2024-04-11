bolt is a censorship-resistant, distributed proof-of-work blockchain. miners
are rewarded in bolt for solving blocks, the native currency of the chain.

### features

- **custom hashing function**: designed to attempt to provide similar performance between cpu and gpu mining.
- **native chain currency**: bolt has its native currency for rewarding miners.
- **proof of work**: the blockchain is designed to inherit bitcoin's best characteristics, including.
  - automatic difficulty adjustments and target block times.
  - fixed supply cap and decreasing issuance of block rewards.
  - the chain can be configured to use bolt's custom hashing function, sha256 or scrypt.

### stack

- nodejs
  - blockchain node
- rust
  - custom hash export
  - v8 contract execution service
- storage
  - mongodb
  - redis

### fair distribution
when mainnet is launched anyone interested will be able to run a node and 
begin mining blocks and will be eligible for the block subsidy reward.

there will be no preallocated tokens of any kind, no airdrop of any kind,
and no fundraising or premine of any kind.

---

### @todo
- [x] enforce bolthash to produce sha256 like hex only outputs with same len (64)
  - [x] rebuild node module and test
  - [x] rebuild cli tool and test
  - [ ] fix webasm library
- [ ] peer functionality
  - [ ] add tor functionality
  - [ ] add peer discovery and sync
    - [ ] utilize ipfs pubsub wrapper
        - command: `list <cid>`
        - command: `peer <ip>`
- [ ] dockerize node setup and streamline deployment process
- [ ] add block explorer (`/explorer/`)
- [ ] add browser extension or electron wallet (`/wallet/`)

