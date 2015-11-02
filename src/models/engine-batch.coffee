{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-batch')
_ = require 'lodash'

class EngineBatch extends Transform
  constructor: (options) ->
    super objectMode: true
    {@flowId, instanceId} = options
    EngineBatch.batches ?= {}

  _transform: (message, enc, next) =>
    if EngineBatch.batches[@flowId]?
      debug 'batching', message
      EngineBatch.addToBatch @flowId, message
      return next()


    EngineBatch.batches[@flowId] =
      devices: ['*']
      topic: 'message-batch'
      payload:
        messages: [message]

    setTimeout =>
      debug 'emitting', EngineBatch.batches[@flowId]
      @push EngineBatch.batches[@flowId]
      delete EngineBatch.batches[@flowId]
      next()
    , 100

  @addToBatch: (flowId, message) ->
    EngineBatch.batches[flowId].payload.messages.push message

module.exports = EngineBatch
