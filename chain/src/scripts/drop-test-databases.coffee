#!/usr/bin/env coffee
config = require __dirname + '/../lib/globals'
helpers = require __dirname + '/../lib/helpers'

await helpers.sleep 1000

result = await mongoose.connection.db.admin().listDatabases()

testDbs = result.databases.filter (db) ->
  if db.name.startsWith('boltstage-') then return true
  false

mongoose.connection.close()

if !testDbs?.length
  throw new Error 'No test databases found'

log 'Databases found to drop: ', testDbs.length, testDbs

if !(answer = await helpers.confirm 'Are you sure you want to drop these databases?', 'Y')
  throw new Error 'User aborted script'

# do drop
for db in testDbs
  options = {}

  dbUrl = config.storage.mongo.split('/')
  dbUrl.pop()
  dbUrl = dbUrl.join '/'

  con = await mongoose.createConnection((connUrl = dbUrl + '/' + db.name), options)
  if await con.dropDatabase()
    log 'Dropped', connUrl
  else
    log 'Failed to drop ', db.name
  con.close()

log 'Finished'
process.exit(0)
