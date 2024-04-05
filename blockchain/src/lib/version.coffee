# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
fs = require 'fs'
exec = require('child_process').exec

{ log } = console
{ exit, env } = process

class Version
  constructor: ->
    @loadPackage()
    @staging = false
    if env.STAGING or env.STAGE
      @staging = true

  loadPackage: ->
    @packageFile = __dirname + '/../../package.json'
    @package = JSON.parse(fs.readFileSync(__dirname + '/../../package.json'))
    @package.versionInt = @getVersionInt()
    try delete @package.dependencies

  getPrefix: (delimiter = '-') ->
    parts = ['bolt']
    parts[0] = 'boltstage' if @staging
    parts.push @getVersionInt()
    parts.join delimiter

  getVersionInt: ->
    [major, minor, patch] = @package.version.split('.').map(Number)
    major * 1000000 + minor * 1000 + patch

  bump: (type = 'patch') ->
    new Promise (resolve, reject) =>
      return reject 'invalid `type`' unless type in ['major', 'minor', 'patch']

      exec "npm version #{type} --no-git-tag-version", (error, stdout, stderr) =>
        if error or stderr
          reject error or stderr
        else
          @loadPackage()
          resolve @package.version

  info: ->
    staging: @staging
    version: @package.version
    versionInt: @package.versionInt
    prefix: @getPrefix()
    prefixMongo: @getPrefix '-'
    prefixRedis: @getPrefix ':'

versionClient = new Version()
module.exports = versionClient

if !module.parent
  log /hello nonparent/
  log versionClient.info()
  await versionClient.bump()
  log versionClient.info()
  exit 0

