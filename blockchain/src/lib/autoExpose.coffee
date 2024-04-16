# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
{ log, L } = require './logger'

_ = require 'lodash'
express = require 'express'

pagination = require './pagination'

modelRouter = (({ model }) ->
  if !model
    throw new Error "`opt.model required"

  opt = model.EXPOSE
  router = express.Router()

  # expose schema methods
  if opt?.methods?.length and _.keys(model.schema.methods).length
    for x in _.keys(model.schema.methods)
      continue if x !in opt.methods

      do (x) =>
        L.note "binding `#{model.modelName}.methods.#{x}()` to `POST #{model.EXPOSE.route}/:_id/#{x}`"

        router.post "/:_id/#{x}", (req,res,next) ->
          try
            item = await model
              .findOne({_id:req.params._id})
              .exec()
          catch e
            return next e

          if !item then return next new Error 'document not found'

          try
            r = await item[x](req.body)
          catch e
            return next e

          return res.respond r

  # bind schema statics
  if opt?.statics?.length and _.keys(model.schema.statics).length
    for x in _.keys(model.schema.statics)
      continue if x !in opt.statics

      do (x) =>
        L.note "binding `#{model.modelName}.statics.#{x}()` to `POST #{model.EXPOSE.route}/#{x}`"

        router.post "/#{x}", (req,res,next) ->
          try
            r = await model[x](req.body)
          catch e
            return next e
          return res.respond r

  L.note "creating crud routes for `#{model.modelName}` to `#{model.EXPOSE.route}`"

  # bind create
  router.post '/', (req,res,next) ->
    try
      r = await model.create req.body
    catch e
      return next e
    return res.respond r

  # bind findOne
  router.get '/:_id', (req,res,next) ->
    try
      item = await model
        .findOne({_id:req.params._id})
        .populate(req.query.populate ? '')
        .lean()
        .exec()
    catch e
      return next e

    if !item then return next new Error 'document not found'
    return res.respond item

  # bind update
  router.post '/:_id', (req,res,next) ->
    try
      item = await model
        .findOne({_id:req.params._id})
        .exec()
    catch e
      return next e

    if !item then return next new Error 'document not found'

    item[k] = v for k,v of req.body

    try
      r = await item.save()
    catch e
      return next e

    return res.respond r

  # bind delete
  router.delete '/:_id', (req,res,next) ->
    try
      item = await model
        .findOne({ _id: req.params._id })
        .exec()
    catch e
      return next e

    if !item then return next new Error 'document not found'

    try
      r = await item.deleteOne()
    catch e
      return next e

    return res.respond r

  # bind list
  router.get '/', (req,res,next) ->
    data = {}

    try
      data.total = await model
        .countDocuments req.coffeeFilter ? {}
        .exec()
    catch e
      return next e

    data.pages = pagination {
      total: data.total
      curPage: +(req.query.page ? 0)
      perPage: +(req.query.perPage ? req.query.limit ? 100)
      arrowMode: yes
    }

    try
      data.items = await model
        .find req.coffeeFilter ? {}
        .sort req.coffeeFilterSort ? {ctime:-1}
        .skip data.pages.offset
        .populate(req.query.populate ? '')
        .limit +(req.query.perPage ? req.query.limit ? 100)
        .lean()
        .exec()
    catch e
      return next e

    return res.respond data

  return router
)

module.exports = {
  modelRouter
}

