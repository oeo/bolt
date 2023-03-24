const log = require('pino')()

if (process.env.NODE_ENV != 'production')
  log.level = 'trace'

module.exports = {
  log,
}