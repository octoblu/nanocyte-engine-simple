{Transform} = require 'stream'
_ = require 'lodash'

class EngineBatch extends Transform
  constructor: ->
    super objectMode: true

  _transform: (envelope, enc, next) =>
    EngineBatch.batches ?= {}

    if EngineBatch.batches[envelope.flowId]?
      EngineBatch.addToBatch envelope.flowId, envelope.message
      @push null
      next()
      return

    EngineBatch.batches[envelope.flowId] =
      flowId:     envelope.flowId
      instanceId: envelope.instanceId
      toNodeId:   envelope.toNodeId
      message:
        topic: 'message-batch'
        payload:
          messages: [envelope.message]

    setTimeout =>
      @push EngineBatch.batches[envelope.flowId]
      delete EngineBatch.batches[envelope.flowId]
      @push null
    , 100
    next()

  @addToBatch: (flowId, message) ->
    EngineBatch.batches[flowId].message.payload.messages.push message

module.exports = EngineBatch
