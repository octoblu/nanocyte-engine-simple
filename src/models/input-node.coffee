_ = require 'lodash'
Router = require './router'

class InputNode
  constructor: (dependencies={}) ->
    @router = dependencies.router ? new Router

  onMessage: (message) =>
    fromNodeId = message.payload?.from ? message.fromUuid
    return console.error 'inputNode could not infer fromNodeId' unless fromNodeId?
    payload = _.omit message.payload, 'from'

    @router.onEnvelope
      flowId:     message.flowId
      instanceId: message.instanceId
      fromNodeId: fromNodeId
      message:    payload

module.exports = InputNode
