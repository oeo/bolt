# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
_ = require 'lodash'
vm = require 'vm'
coffee = require 'coffeescript'

module.exports = coffeeQuery = {}

coffeeQuery.convert = (str) ->
  result = {}

  str = str.trim()
  str = '{' + str + '}' unless str.startsWith('{')

  result.original = str

  try
    compiled = coffee.compile "_tmpObj = #{str}", bare: true

    sandbox = _tmpObj: {}
    vm.runInNewContext compiled, sandbox

    if typeof(sandbox) is 'object'
      result.ok = true
      result.valid = true

      try
        for key, value of sandbox._tmpObj
          if typeof(value) is 'regexp'
            continue if value.toString().includes('//')

            value = value.toString()

            if value.startsWith('/')
              value = value.substr(1)

            [expression, flags] = value.split('/')

            value = new RegExp(expression, flags ? '')
            sandbox._tmpObj[key] = value

      result.result = sandbox._tmpObj
    else
      result.ok = false
      result.valid = false

  catch
    result.ok = false
    result.valid = false

  result

coffeeQuery.parseExtraFilters = (req, res, next) ->
  req.extraFilters = {}

  filter = {}

  for key, value of req.query
    if key.startsWith('filter.')
      name = key.substr("filter.".length)
      tmp = coffeeQuery.convert value

      if tmp.ok
        filter[key] = value for key, value of tmp.result

  if _.size(filter)
    req.extraFilters = filter
      
  next()

coffeeQuery.middleware = (req, res, next) ->
  inp = req.query.filter ? req.body.filter
  sortInp = req.query.sort ? req.body.sort

  req.coffeeFilter = null
  req.coffeeFilterSort = null

  if inp and typeof(inp) is 'string'
    r = coffeeQuery.convert inp.trim()
    if r.result
      req.coffeeFilter = r.result
      res.locals.coffeeFilter = inp.trim()

  if sortInp and typeof(sortInp) is 'string'
    r = coffeeQuery.convert sortInp.trim()
    if r.result
      req.metadata.sort = req.coffeeFilterSort = r.result
      res.locals.coffeeFilterSort = sortInp.trim()

  # Append extra filters if they exist
  if req.extraFilters? and _.size(req.extraFilters)
    req.coffeeFilter = {} unless req.coffeeFilter
    req.coffeeFilter[key] = value for key, value of req.extraFilters

  req.metadata.filter = req.coffeeFilter ? {}
      
  next()

###
tests = [
  "{_id:'one','userdata.geoCountry':'US'}"
  "invalid"
  null
]

for test in tests
  console.log coffeeQuery.convert test

{ ok: true,
  valid: true,
  result: { _id: 'one', 'userdata.geoCountry': 'US' } }
{ ok: false, valid: false }
{ ok: false, valid: false }
###

