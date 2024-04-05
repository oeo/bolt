VERSION = 'furious-fish'
STAGING = true

_clone = (x) -> JSON.parse JSON.stringify(x)

pkg = _clone(require(__dirname + '/../package.json'))
try delete pkg.dependencies

config = {
  package: pkg

  version: pkg.version
  versionName: VERSION

  staging: false

  # valid: [sha256, scrypt, bolthash]
  algo: 'bolthash'

  minFee: 0.0001
  maxBlockSize: 1024 * 1024
  maxContractStateSize: 1024 * 1024
  maxTransactionsPerBlock: 4000
  maxTransactionCommentSize: 32
  maxBlockCommentSize: 32
  maxContractCommentSize: 32
  rewardDefault: 50
  rewardHalvingInterval: 210000 # blocks
  blockInterval: 60 * 60 # 1hr 
  difficultyDefault: 100
  difficultyChangePercent: 1
  difficultyChangePercentDrastic: 25
  difficultyChangeBlockConsideration: 3
  confirmations: 6

  # m/84h/779h/0h/0h
  # https://github.com/satoshilabs/slips/blob/master/slip-0044.md
  derivation: {
    purpose: 84
    coinType: 779
    account: 0
    change: 0
    index: 0
  }

  storage: {
    mongo: 'mongodb://127.0.0.1:27017/prod-' + VERSION
    redis: 'redis://127.0.0.1:6379/'
  }

  ports: {
    ws: 12121
    http: 12120
  }
}

configStaging = {
  version: pkg.version
  staging: true
  blockInterval: 10
  rewardHalvingInterval: 50
  storage: {
    mongo: 'mongodb://127.0.0.1:27017/stage-' + VERSION
    redis: 'redis://127.0.0.1:6379'
  }
}

if STAGING
  config[k] = v for k,v of configStaging

config.genesisBlock = {
  _id: 0
  transactions: []
  hash_previous: '0000000000000000000000000000000000000000000000000000000000000000'
  difficulty: config.difficultyDefault
  comment: 'we will craft citadels in the clouds or bury vaults within the ashes.'
}

if !module.parent
  console.log JSON.stringify config, null, 2

module.exports = config

