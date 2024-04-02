# bolt
<img src="assets/bolt-reverse.svg" height="65" align="right" />
bolt is a censorship-resistant, distributed proof-of-work blockchain designed 
to have bitcoin's best characteristics. The blockchain is built using using 
coffeescript and leverages it's [custom hashing function](../hash/rust) for 
balanced performance between cpu and gpu mining. miners are rewarded in bolt,
the native currency of the chain.

## fair distribution
bolt intends to launch with a fair distribution and without a premine or fundraising.
the block time and issuance schedule is designed to follow roughly the 
schedule and behviour of bitcoin.

## features

- **censorship resistance**: bolt allows for immutable data posting, making it resistant to censorship.
- **custom hashing function**: designed to attempt to provide similar performance between cpu and gpu mining.
- **native currency**: bolt has its native currency for rewarding miners.
- **bitcoin characteristics**: the blockchain is designed to inherit bitcoin's characteristics.

### files & directories

- `assets/`: contains static assets and brandables.
- `blockchain/`: contains the blockchain component written in coffeescript
- `hash/rust/`: contains the custom hashing function that is written in rust

## @todo
- [ ] `block-explorer/`: contains a react-based block explorer gui.
- [ ] `browser-wallet/`: contains the chrome and firefox wallet extension.

