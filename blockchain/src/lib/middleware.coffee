# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
{ log } = console
{ env, exit } = process

middleware = {}

# request method override
middleware.methodOverride = (req, res, next) ->
  if req.query?.method?
    method = req.query.method.toLowerCase()

    validMethods = [
      'post'
      'get'
      'delete'
      'put'
      'patch'
    ]

    if method in validMethods
      req.method = method.toUpperCase()

      if method isnt 'get'
        req.body = req.query
        req.query = {}

  return next()

middleware.metadata = (req, res, next) ->
  req.metadata = {
    start: Date.now()
    path: req.path
    method: req.method
    query: req.query
    body: req.body
  }

  return next()

middleware.respond = (req, res, next) ->
  res.respond = (data = null, status = null) ->
    req.metadata.elapsed = Date.now() - req.metadata.start
    delete req.metadata.start

    if data instanceof Error
      obj =
        ok: no
        response: data.toString()
        error: data.toString().split("Error: ").pop()

      if env?.NODE_ENV isnt 'production'
        obj.errorStack = data.stack
    else
      obj =
        ok: yes
        response: data

    obj._meta = req.metadata

    res.status = status if status

    format = req.query.format ? req.body.format ? 'json'
    format = format.toLowerCase()

    if format !in ['json', 'jsonp']
      format = 'json'

    if format is 'json'
      if req.query.pretty
        res.set 'content-type', 'text/json'
        return res.end JSON.stringify obj, null, 2
      else
        return res.json obj

    else if format is 'jsonp'
      if (cbfn = req.query.cb) and !req.query.callback
        req.query.callback = cbfn
      return res.jsonp obj

  return next()

middleware.realIp = (req, res, next) ->
  req.realIp = req.headers['x-forwarded-for']?.split(',')[0]?.trim() or req.ip

  needles = [
    ':ffff:'
    '127.0.0.1'
    '::'
  ]

  for x in needles
    if req.realIp.includes(x)
      req.realIp = '127.0.0.1'
      break

  return next()

module.exports = middleware

