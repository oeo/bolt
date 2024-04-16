# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
config = require './lib/globals'

express = require 'express'

cors = require 'cors'
bodyParser = require 'body-parser'
compression = require 'compression'

middleware = require './lib/middleware'
coffeeQuery = require './lib/coffeeQuery'

app = express()
app.disable 'x-powered-by'

app.use bodyParser.json()
app.use bodyParser.urlencoded({ extended: true })
app.use compression()
app.use cors()

app.use middleware.realIp
app.use middleware.methodOverride
app.use middleware.metadata
app.use middleware.respond
app.use coffeeQuery.parseExtraFilters
app.use coffeeQuery.middleware

{ modelRouter } = require './lib/autoExpose'

for _k, model of (require './models')
  continue if !model.EXPOSE
  try
    router = modelRouter({ model })
    app.use model.EXPOSE.route, router
  catch e
    throw e

app.get '/', ((req, res, next) ->
  res.respond {
    info: version.info()
    uptime: Math.round(process.uptime())
  }
)

# handle errors
app.use (err, req, res, next) ->
  L.error e
  res.respond err, 500

# handle 404
app.use (req,res,next) ->
  doIgnore = false

  for x in [
    'favicon'
    'robots.txt'
  ]
    if req.url.includes(x)
      doIgnore = true
      break

  if !doIgnore
    L.debug '404', req.method.toLowerCase(), req.url

  return res.respond (new Error '404'), 404

main = (->
  bulk =  require('fs').readFileSync(__dirname + '/../.ascii.art','utf8')

  lines = _.map bulk.split('\n'), (line) ->

    line = line.split('_algo_').join(config.algo)
    line = line.split('_version_').join(config.package.version)
    line = line.split('_versionInt_').join(config.versionInt)

    while line.length < (maxLen = 42)
      line += ' '

    while line.length > maxLen
      line = line.substr(0, line.length - 1)

    line

  bulk = lines.join '\n'

  randomColor = _.sample [
    colors.inverse.yellow
    colors.inverse.green
    colors.inverse.blue
  ]

  log randomColor(bulk) + '\n'

  L "node identity #{identity.address}"

  app.listen config.ports.http, (e) ->
    if e then throw e
    L "http listening on #{config.ports.http}"
)

module.exports = {
  app
  main
}

main() if !module.parent

