_ = require 'lodash'
Router = require './router'

class InputNode
  constructor: (dependencies={}) ->
    @router = dependencies.router ? new Router
    @triggerNode = require './wrapped-trigger-node'

  onMessage: (message) =>
    payload = _.omit message.payload, 'from'

    @router.onEnvelope
      flowId:     message.flowId
      instanceId: message.instanceId
      fromNodeId: message.payload.from
      message:    payload

module.exports = InputNode
