config = require './config'

_ = require 'lodash'

Block = require './models/block'

genesisBlock = new Block(_.clone config.genesisBlock)
log /block/, genesisBlock

hash = await genesisBlock.calculateHash()
log /block-hash/, hash

solved = await genesisBlock.mine()

log /solved/, solved 
log /current object after solve/, genesisBlock

log /validating block hash/

valid = await genesisBlock.validateHash(solved)
log /valid/, valid

log /final block/
log genesisBlock

##valid = await genesisBlock.validate()
##log /valid/, valid
