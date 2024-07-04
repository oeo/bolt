# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2
assert = require 'assert'

describe 'counting', ->

  it 'should count from 1 to 10', ->
    count = 0
    for i in [1..10]
      count += 1
    assert.equal count, 10

