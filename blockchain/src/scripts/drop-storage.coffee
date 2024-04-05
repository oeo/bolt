#!/usr/bin/env coffee
{ env, exit } = process

config = require __dirname + '/../lib/globals'
helpers = require __dirname + '/../lib/helpers'

L 'connecting to mongodb'

await helpers.sleep 1000

result = await mongoose.connection.db.admin().listDatabases()

allDbs = result.databases.filter (db) ->
  if db.name.startsWith('bolt-') then return true
  if db.name.startsWith('boltstage-') then return true
  false

mongoose.connection.close()

if !allDbs?.length
  L.error 'No databases found'
  exit 1

L.warn 'mongo databases found to drop', (_.map allDbs, (x) -> x.name.trim()).join ' '

if !(answer = await helpers.confirm 'are you sure you want to drop these databases?', 'Y')
  L.error 'user aborted script'
  exit 1

# drop mongo collections
for db in allDbs
  options = {}

  dbUrl = config.storage.mongo.split('/')
  dbUrl.pop()
  dbUrl = dbUrl.join '/'

  con = await mongoose.createConnection((connUrl = dbUrl + '/' + db.name), options)

  if await con.dropDatabase()
    L.success 'dropped database', db.name
  else
    L.error 'failed to drop database', db.name

  con.close()

L.success 'finished'
exit 0

