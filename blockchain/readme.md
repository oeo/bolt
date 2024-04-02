<p align="center">
  <img src="../assets/bolt.svg" height="65"/>
</p>

bolt is a censorship-resistant, distributed proof-of-work blockchain designed 
to have bitcoin's best characteristics. The blockchain is built using using 
coffeescript and leverages it's [custom hashing function](../hash/rust) for 
balanced performance between cpu and gpu mining. miners are rewarded in bolt,
the native currency of the chain.

## features

- **censorship resistance**: bolt allows for immutable data posting, making it resistant to censorship.
- **custom hashing function**: designed to attempt to provide similar performance between cpu and gpu mining.
- **native currency**: bolt has its native currency for rewarding miners.
- **bitcoin characteristics**: the blockchain is designed to inherit bitcoin's characteristics.

## getting started

### prerequisites

- node.js
- coffeescript
- mongodb
- redis

### installation

1. clone the repository
2. install dependencies
3. update the `config.coffee` file as necessary
4. run the miner

### files & directories

#### main files
- `miner.coffee`: contains the mining logic and environment setup.
- `config.coffee`: holds global configurations for the blockchain.

#### models
- `models/contract.coffee`: defines smart contracts.
- `models/blockchain.coffee`: contains main blockchain logic.
- `models/transaction.coffee`: defines transactions.
- `models/block.coffee`: defines blocks.

#### libraries
- `lib/helpers.coffee`: provides utility functions.
- `lib/wallet.coffee`: manages wallet operations.

#### scripts
- `scripts/generate-wallets.coffee`: utility script for generating wallets.

## configuration

- `VERSION`: blockchain version
- `STAGING`: staging environment flag
- `minFee`: minimum transaction fee
- `maxBlockSize`: maximum block size
- `rewardDefault`: default block reward
- `difficultyDefault`: default mining difficulty

for more details, refer to `config.coffee`.

