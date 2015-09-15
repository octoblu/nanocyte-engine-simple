_ = require 'lodash'

class Router
  constructor: (dependencies={}) ->
    {@datastore} = dependencies
    @datastore ?= require '../handlers/datastore-handler'

    @nodes =
      'nanocyte-node-debug': require './wrapped-debug-node'
      'meshblu-output':      require '../handlers/meshblu-output-handler'

  onMessage: (envelope) =>
    @datastore.get "#{envelope.flowId}/router/config", (error, routerConfig) =>
      senderNodeConfig = routerConfig[envelope.toNodeId]

      _.each senderNodeConfig.linkedTo, (uuid) =>
        receiverNodeConfig = routerConfig[uuid]
        receiverNode = @nodes[receiverNodeConfig.type]

        receiverNode.onMessage
          flowId:  envelope.flowId
          message: envelope.message
          toNodeId:  uuid
          fromNodeId: envelope.toNodeId
        , (error, envelope) =>
          @onMessage envelope

module.exports = Router
