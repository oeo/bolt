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

# Error handling middleware
app.use (err, req, res, next) ->
  console.error err.stack
  res.status(500).json({ error: 'Internal Server Error' })

# Graceful shutdown handling
require('process').on 'exit', ->
  # @todo: Perform any necessary cleanup tasks before exiting
  process.exit()

main = (->
  log 'Initializing Bolt Node...'

  app.listen config.ports.http, ->
    log "Bolt Node API server is running on port #{config.ports.http}"
)

# Start the node
main()

