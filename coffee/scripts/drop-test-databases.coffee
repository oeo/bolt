#!/usr/bin/env coffee
config = require __dirname + '/../config'
{confirm} = require __dirname + '/../lib/helpers'

mongoose = require 'mongoose'

dbUrl = config.storage.mongo.substr(0,config.storage.mongo.lastIndexOf('/')) + '/'

options = {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  writeConcern: { w: "majority" }
}

await mongoose.connect dbUrl, options 
console.log 'Connected to MongoDB server'

result = await mongoose.connection.db.admin().listDatabases()
testDbs = result.databases.filter (db) ->
  if db.name.startsWith('stage-') then return true
  false

mongoose.connection.close()

if !testDbs?.length
  throw new Error 'No test databases found'

log 'Databases found to drop: ', testDbs.length, testDbs

if !(answer = await confirm 'Are you sure you want to drop these databases?', 'Y')
  throw new Error 'User aborted script'

# do drop
for db in testDbs
  con = await mongoose.createConnection((connUrl = dbUrl + db.name), options)
  if await con.dropDatabase()
    log 'Dropped', connUrl 
  else
    log 'Failed to drop ', db.name
  con.close()

log 'Finished'
process.exit(0)
