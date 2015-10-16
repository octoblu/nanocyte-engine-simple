_  = require 'lodash'
Base = require '../classes/base.coffee'

class SimpleTest extends Base
  constructor: ->
    @label = "SimpleTest"

  run: (callback=->) =>
    _.delay callback, 100

module.exports = SimpleTest
