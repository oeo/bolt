<p align="center">
  <img src="assets/logo-red-bg.svg" height="200">
</p>

bolt is a censorship-resistant, distributed proof-of-work blockchain. miners
are rewarded in bolt for solving blocks, the native currency of the chain.

## features

- **custom hashing function**: designed to attempt to provide similar performance between cpu and gpu mining.
- **native chain currency**: bolt has its native currency for rewarding miners.
- **proof of work**: the blockchain is designed to inherit bitcoin's best characteristics.
  - automatic difficulty adjustments and target block times.
  - fixed supply cap and decreasing issuance of block rewards.
  - the chain can be configured to use bolt's custom hashing function, sha256 or scrypt.

## stack

- nodejs
  - blockchain node
- rust
  - custom hash function
  - v8 contract execution service
- storage
  - mongodb
  - redis

## fair distribution
when mainnet is launched anyone interested will be able to run a node and 
begin mining blocks and will be eligible for the block subsidy reward.

there will be no preallocated tokens of any kind, no airdrop of any kind,
and no fundraising or premine of any kind.

---

### @todo
- [x] enforce bolthash to produce sha256 like hex only outputs with same len
  - [x] rebuild node module and test
  - [x] rebuild cli tool and test
  - [ ] fix webasm export
- [ ] p2p
  - [ ] add tor capability
  - [ ] add p2p discovery
    - [ ] utilize ipfs pubsub
      - lift the libp2p logic and write as service or wrap ipfs itself
- [ ] dockerize node setup and streamline deployment process
- [ ] add concept block explorer (react)
- [ ] create standalone wallet (electron?/web?/browserext?)
- [ ] dockerize everything

### ambitions
- rust-based v8 smart contract executor
  - allows newcomers to write in a familiar syntax while maintaining strict execution and computation limits for miners
  - highly performant and circumvents nodejs' single-threaded nature

