config = require './lib/globals'

express = require 'express'
bodyParser = require 'body-parser'
morgan = require 'morgan'
cors = require 'cors'
compression = require 'compression'

app = express()
app.disable 'x-powered-by'

# Middleware
app.use bodyParser.json()
app.use bodyParser.urlencoded({ extended: true })
app.use morgan('dev')
app.use cors()
app.use compression()

# Route files
blockchainRoutes = require './routes/blockchain'
transactionsRoutes = require './routes/transactions'
walletsRoutes = require './routes/wallets'
miningRoutes = require './routes/mining'
networkRoutes = require './routes/network'
contractsRoutes = require './routes/contracts'
statsRoutes = require './routes/stats'

# Setup versioned API
apiRouterV1 = express.Router()
app.use '/api/v1', apiRouterV1

apiRouterV1.use '/blockchain', blockchainRoutes
apiRouterV1.use '/transactions', transactionsRoutes
apiRouterV1.use '/wallets', walletsRoutes
apiRouterV1.use '/mining', miningRoutes
apiRouterV1.use '/network', networkRoutes
apiRouterV1.use '/contracts', contractsRoutes
apiRouterV1.use '/stats', statsRoutes

# lmao lmfao
app.use (err, req, res, next) ->
  console.error err.stack
  res.status(500).json({ error: 'Internal Server Error' })

# graceful shutdown handling
require('process').on 'exit', process.exit

main = (->
  bulk =  require('fs').readFileSync(__dirname + '/../.ascii.art','utf8')

  lines = _.map bulk.split('\n'), (line) ->
    line = line.split('_algo_').join(config.algo)
    line = line.split('_version_').join(config.package.version)
    line = line.split('_name_').join(config.package.version)

    while line.length < (maxLen = 44)
      line += ' '

    while line.length > maxLen
      line = line.substr(0, line.length - 1)

    line

  bulk = lines.join '\n'

  randomColor = _.sample [
    colors.inverse.red
    colors.inverse.yellow
    colors.dim
    colors.inverse.green
    colors.inverse.blue
  ]

  log randomColor(bulk)

  log 'initializing bolt node'

  app.listen config.ports.http, ->
    log "listening on port #{config.ports.http}"
)

# Start the node
main()

