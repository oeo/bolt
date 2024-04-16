# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
{ log, L } = require './logger'
{ env, exit } = process

models = {}

# auto expose model to rest
models.EXPOSE = (model, opts = {}) ->
  if opts?.route
    model.EXPOSE = opts
    return model

  opts = {
    route: "/#{model.collection.name}"
    methods: _.keys(model.schema.methods)
    statics: _.keys(model.schema.statics)
  }

  model.EXPOSE = opts
  return model

module.exports = models

