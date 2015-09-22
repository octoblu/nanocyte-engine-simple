_ = require 'lodash'
Router = require './router'

class InputNode
  constructor: (dependencies={}) ->
    @router = dependencies.router ? new Router

  onMessage: (message) =>
    return console.error 'inputNode message was missing "payload"' unless message.payload?
    return console.error 'inputNode message.payload was missing "from"' unless message.payload.from?
    payload = _.omit message.payload, 'from'

    @router.onEnvelope
      flowId:     message.flowId
      instanceId: message.instanceId
      fromNodeId: message.payload.from
      message:    payload

module.exports = InputNode
