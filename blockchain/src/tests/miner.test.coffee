# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
process.env.TESTING = 1
process.env.STAGING = 1

config = require './../lib/globals'
{ time } = require './../lib/helpers'

Wallet = require './../lib/wallet'
Blockchain = require './../lib/blockchain'

Block = require './../models/block'
{ Transaction } = require './../models/transaction'

assert = require 'assert'
after -> process.exit 0

blockchain = null
wallet = null
nextBlock = null
solvedBlock = null
difficultyHistory = []

describe 'mining', ->

  it 'should drop all blockchain data', ->
    try
      result = await mongoose.connection.db.admin().listDatabases()

      allDbs = result.databases.filter (db) ->
        if db.name.startsWith('bolt-') then return true
        if db.name.startsWith('boltstage-') then return true
        false

      return true if !allDbs?.length

      for db in allDbs
        options = {}

        dbUrl = config.storage.mongo.split('/')
        dbUrl.pop()
        dbUrl = dbUrl.join '/'

        con = await mongoose.createConnection((connUrl = dbUrl + '/' + db.name), options)

        await con.dropDatabase()
    catch e
      throw e

    return true

  it 'should create a new blockchain instance', ->
    try
      blockchain = new Blockchain({ config })
    catch e
      throw e

    return true

  it 'should init and validate the blockchain', ->
    try
      await blockchain.init()
    catch e
      throw e

    validResult = await blockchain.validate()
    assert.equal validResult, true

  it 'should generate wallet with address 2igcqR1rSiNFeie7sCG9XQQT', ->
    wallet = new Wallet({
      seed: 'boss first fantasy world coin magic casual dutch vapor arctic bag keep'
    })

    assert.equal wallet?.address, '2igcqR1rSiNFeie7sCG9XQQT'

  it 'wallet should use the initiated blockchain', ->
    wallet.use(blockchain)
    assert.equal wallet._blockchain._id, blockchain._id

  it 'should get the next block template', ->
    nextBlock = await blockchain.nextBlock(wallet)
    assert !!nextBlock._id, true

  it 'should mine and validate the next block', ->
    @timeout 60000

    try
      solvedHash = await nextBlock.mine()
    catch e
      throw e

    nextBlock.hash = solvedHash

    nextBlockValid = await nextBlock.tryValidate()
    assert.equal nextBlockValid, true

  it 'should save the newly mined block (height=1)', ->
    solvedBlock = await nextBlock.save()

    difficultyHistory.push {
      height: solvedBlock._id
      difficulty: solvedBlock.difficulty
    }

    assert.equal solvedBlock._id, 1

  it 'should have the block reward as the correct address', ->
    assert.equal true, !!_.find(solvedBlock.transactions, {
      comment: 'block_reward'
      to: '2igcqR1rSiNFeie7sCG9XQQT'
    })

  it 'the current block should be the block we just solved', ->
    curBlock = await Block
      .findOne({ blockchain: config.versionInt })
      .sort({ _id: -1 })
      .limit 1

    assert.equal curBlock.hash, solvedBlock.hash

  it 'blockchain should validate now', ->
    validResult = await blockchain.validate()
    assert.equal validResult, true

  it 'should mine as many blocks as it takes to hit the difficulty adjustment', ->
    @timeout 60000
    success = 0

    for x in [1..config.difficultyAdjustmentInterval - 1]
      newBlock = await blockchain.nextBlock(wallet)
      newBlock.hash = await newBlock.mine()
      saveBlock = await newBlock.save()
      success += 1

      difficultyHistory.push {
        height: saveBlock._id
        difficulty: saveBlock.difficulty
      }

    assert.equal success, config.difficultyAdjustmentInterval - 1

  it 'should validate the blockchain again', ->
    validResult = await blockchain.validate()
    assert.equal validResult, true

  it "should validate the block height as config.difficultyAdjustmentInterval (#{config.difficultyAdjustmentInterval})", ->
    curBlock = await blockchain.getLastBlock()
    assert.equal curBlock._id, (config.difficultyAdjustmentInterval)

  it 'miner should have a balance of (config.difficultyAdjustmentInterval) * config.rewardDefault', ->
    balance = await wallet.getBalance()
    assert.equal (config.rewardDefault * (config.difficultyAdjustmentInterval)), balance

  it "difficulty should increase on the config.difficultyAdjustmentInterval (#{config.difficultyAdjustmentInterval}) block", ->
    history = difficultyHistory

    pop1 = history.pop()
    pop2 = history.pop()

    assert.ok (pop1.difficulty > pop2.difficulty), 'difficulty did not increase'

  it 'a new wallet should mine 10 more blocks', ->
    @timeout 60000

    newWallet = new Wallet()
    newWallet.use blockchain

    success = 0

    for x in [1..10]
      newBlock = await blockchain.nextBlock(newWallet)
      newBlock.hash = await newBlock.mine()
      saveBlock = await newBlock.save()
      success += 1

    assert.equal success, 10

  it "the block height should be config.difficultyAdjustmentInterval (#{config.difficultyAdjustmentInterval}) + 10)", ->
    curBlock = await blockchain.getLastBlock()
    assert.equal config.difficultyAdjustmentInterval + 10, curBlock._id

  it 'blockchain should validate again', ->
    validResult = await blockchain.validate()
    assert.equal validResult, true

