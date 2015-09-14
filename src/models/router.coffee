_ = require 'lodash'

class Router
  constructor: (dependencies={}) ->
    {@datastore} = dependencies
    @datastore ?= require '../handlers/datastore-handler'

    @nodes =
      'nanocyte-node-debug': require './wrapped-debug-node'
      'meshblu-output':      require './wrapped-meshblu-output-node'

  onMessage: (envelope) =>
    @datastore.get envelope.flowId, (error, routerConfig) =>
      senderNodeConfig = routerConfig[envelope.nodeId]

      _.each senderNodeConfig.linkedTo, (uuid) =>
        receiverNodeConfig = routerConfig[uuid]
        receiverNode = @nodes[receiverNodeConfig.type]

        receiverNode.onMessage
          flowId:  envelope.flowId
          message: envelope.message
          nodeId:  uuid
        , (error, envelope) =>
          @onMessage envelope

module.exports = Router
