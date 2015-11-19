{Transform} = require 'stream'
debug       = require('debug')('nanocyte-engine-simple:engine-output-throttle')
_           = require 'lodash'
moment      = require 'moment'
Datastore   = require './datastore'

class EngineOutputThrottle extends Transform
  constructor: (options, dependencies={})->
    super objectMode: true
    {@datastore, @moment} = dependencies
    @datastore ?= new Datastore
    @moment    ?= moment

  _transform: (envelope, enc, next) =>
    envelope = _.clone envelope
    {config} = envelope

    key = "#{config.uuid}:#{@moment().unix()}"
    @datastore.getAndIncrementCount key, 1, 10, (error, count) =>
      debug 'count', error, count
      next()
      return @push(null) if count > 10

      if count == 10
        toNodeId = envelope.message.payload?.node
        envelope.message =
          topic   : 'debug'
          devices : ['*']
          payload :
            msgType: 'error'
            msg: 'Engine rate limit exceeded'
            node:    toNodeId
        debug 'emitting error', envelope

      debug 'push'

      @push envelope

module.exports = EngineOutputThrottle
