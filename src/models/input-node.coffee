_ = require 'lodash'
Router = require './router'

class InputNode
  constructor: (dependencies={}) ->
    @router = dependencies.router ? new Router
    @triggerNode = require './wrapped-trigger-node'

  onMessage: (message) =>
    payload = _.omit message.payload, 'from'

    envelope =
      flowId:  message.flowId
      nodeId:  message.payload.from
      message: payload

    @triggerNode.onMessage envelope, (error, responseEnvelope) =>
      return console.error error.message if error?
      @router.onMessage responseEnvelope

module.exports = InputNode
