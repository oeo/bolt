const config = require('./config');
const { log } = require('./utils/log')

const { Blockchain } = require('./lib/blockchain');
const { Wallet } = require('./lib/wallet');

// miner
async function main() {
  let blockchain

  try {
    blockchain = await new Blockchain(config)
  } catch (error) {
    log.error(error)
  }

  const minerWallet = new Wallet()

  log.debug('Start mining..')

  // mine blocks 
  while (true) {
    let minedBlock = await blockchain.mineBlock(minerWallet.address)
  }
}

main()
