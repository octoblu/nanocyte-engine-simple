{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-batch')
_ = require 'lodash'

class EngineBatch extends Transform
  constructor: ->
    super objectMode: true
    EngineBatch.batches ?= {}

  _transform: (envelope, enc, next) =>
    next()
    if EngineBatch.batches[envelope.flowId]?
      EngineBatch.addToBatch envelope.flowId, envelope.message      
      return

    EngineBatch.batches[envelope.flowId] =
      flowId:     envelope.flowId
      instanceId: envelope.instanceId
      toNodeId:   'engine-output'
      message:
        devices: ['*']
        topic: 'message-batch'
        payload:
          messages: [envelope.message]

    setTimeout =>
      debug 'emitting', EngineBatch.batches[envelope.flowId]
      @push EngineBatch.batches[envelope.flowId]
      delete EngineBatch.batches[envelope.flowId]
    , 100

  @addToBatch: (flowId, message) ->
    EngineBatch.batches[flowId].message.payload.messages.push message

module.exports = EngineBatch
