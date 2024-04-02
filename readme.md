# bolt
<img src="assets/bolt-reverse.svg" height="85" align="left" />
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

## fair distribution
bolt intends to launch with a fair distribution and without a premine or fundraising.
the block time and issuance schedule is designed to follow roughly the 
schedule and behviour of bitcoin.

### structure

- `assets/`: contains static assets and brandables.
- `blockchain/`: contains the blockchain component written in coffeescript.
- `hash/rust/`: contains the custom hashing function that is written in rust.

## @todo
- [ ] `browser-wallet/`: contains the chrome and firefox wallet extension.
- [ ] `www-explorer/`: contains a react-based block explorer gui.
- [ ] `www-homepage/`: contains the homepage for bolt.

---

## fair distribution
bolt intends to launch with a fair distribution and without a premine and
without fundraising, although there may be an airdrop to existing bitcoin
wallets.

the configured block time and issuance schedule is designed to follow 
roughly the schedule and behviour of bitcoin. at the very least the features of 
digital scarcity and proof of work will remain constant. however, we do reserve
the rights the play with new features such as our own smart contract language and
logic, utilizing different hashing algorythms, and so on. if the community of
nodes accepts our changes they will be implemented. if not, then i suppose
we fell short in some way. it's a real organic dao!

