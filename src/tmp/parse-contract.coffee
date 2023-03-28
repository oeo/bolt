parseContract = (code) ->
  lines = code.split('\n')

  contract = {
    state: {}
    init: ''
    methods: {}
    viewMethods: {}
  }

  methodRegex = /^@(\w+\s+)?(\w+)\s*=\s*(\(.*\))?->/
  stateRegex = /^@state\s*=\s*\{/

  i = 0
  while i < lines.length
    line = lines[i]

    if methodRegex.test(line)
      [, accessModifier, methodName, methodArgs] = line.match(methodRegex)
      methodBody = []

      i++
      while i < lines.length and not /^\s*$|^@/.test(lines[i])
        methodBody.push(lines[i])
        i++

      method = {
        accessModifier: accessModifier?.trim() ? 'public'
        args: methodArgs ? '()'
        body: methodBody.join('\n')
      }

      if methodName in ['init']
        contract[methodName] = method
      else
        if method.accessModifier is 'view'
          contract.viewMethods[methodName] = method
        else
          contract.methods[methodName] = method

    else if stateRegex.test(line)
      stateBody = []

      i++
      while i < lines.length and not /^\s*$|^@/.test(lines[i])
        stateBody.push(lines[i])
        i++

      stateCode = stateBody.join('\n').replace(/^\s+|\s+$/g, '')
      contract.state = eval("({#{stateCode}})")

    else
      i++

  return contract

code = require('fs').readFileSync('./example-contract.coffee').toString()

parsedContract = parseContract(code)
console.log parsedContract

