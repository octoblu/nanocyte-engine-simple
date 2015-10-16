_     = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:process-count-manager')

class ProcessCountManager
  constructor: (@endCallback=_.noop, @metadata)->
    @_transactions = 0

  reset: =>
    @_transactions = 0 # So it goes to 0, ya

  up: =>
    @_transactions++

  down: =>
    @_transactions--

  checkZero: (callback=->) =>
    _.defer =>
      debug "checkZero #{@_transactions}", @metadata
      return callback() unless @_transactions == 0
      debug 'it is done', @metadata
      @endCallback()
      callback()

module.exports = ProcessCountManager
