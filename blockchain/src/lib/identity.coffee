# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
fs = require 'fs'
os = require 'os'
path = require 'path'

L = (require './logger.coffee').L
Wallet = require __dirname + '/wallet'

loadOrCreateIdent = (do ->
  homeDir = os.homedir()

  subFolder = path.join(homeDir, '.bolt')
  identFile = path.join(subFolder, 'identity.json')

  unless fs.existsSync(identFile)
    L 'generating an identity for this node'

    wallet = new Wallet()

    if not fs.existsSync(subFolder)
      fs.mkdirSync(subFolder, { recursive: true }) if not fs.existsSync(subFolder)

    fs.writeFileSync(identFile, JSON.stringify(wallet.toJSON(),null,2))

    L.success 'new identity generated: ' + wallet.addressShort
    L.success 'wrote identity file ' + identFile

  walletObj = JSON.parse(fs.readFileSync(identFile))

  identWallet = new Wallet({
    privateKey: walletObj.privateKey
  })

  return {
    address: walletObj.addressShort
    wallet: identWallet
  }
)

module.exports = loadOrCreateIdent

