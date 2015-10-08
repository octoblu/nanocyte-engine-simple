{Transform} = require 'stream'
debug       = require('debug')('nanocyte-engine-simple:engine-throttle')
_           = require 'lodash'
moment      = require 'moment'
Datastore   = require './datastore'

class EngineThrottle extends Transform
  constructor: (options, dependencies={})->
    super objectMode: true
    {@datastore, @moment} = dependencies
    @datastore ?= new Datastore
    @moment    ?= moment

  _transform: (envelope, enc, next) =>
    envelope = _.cloneDeep envelope
    {config} = envelope

    key = "#{config.uuid}:#{@moment().unix()}"
    @datastore.getAndIncrementCount key, (error, count) =>
      debug 'count', error, count
      return @push null if count > 10

      if count == 10
        nodeId = envelope.message.payload?.node

        envelope.message.topic   = 'debug'
        envelope.message.devices = ['*']
        envelope.message.payload =
          msgType: 'error'
          msg: 'Engine rate limit exceeded'
          node:    nodeId
        debug 'emitting error', envelope

      debug 'push'
      @push envelope

      next()

module.exports = EngineThrottle
