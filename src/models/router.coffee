_ = require 'lodash'

class Router
  constructor: (dependencies={}) ->
    {@datastore} = dependencies

    @nodes =
      'nanocyte-node-debug': require './wrapped-debug-node'

  onMessage: (envelope) =>
    @datastore.get envelope.flowId, (error, flow) =>
      senderNodeConfig = flow[envelope.nodeId]

      _.each senderNodeConfig.linkedTo, (uuid) =>
        receiverNodeConfig = flow[uuid]
        receiverNode = @nodes[receiverNodeConfig.type]
        receiverNode.onMessage
          flowId:  envelope.flowId
          message: envelope.message
          nodeId:  uuid

module.exports = Router
