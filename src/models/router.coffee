_ = require 'lodash'
NodeAssembler = require './node-assembler'

class Router
  constructor: (dependencies={}) ->
    {nodeAssembler,@datastore} = dependencies

    @datastore ?= require '../handlers/datastore-handler'

    nodeAssembler ?= new NodeAssembler()
    @nodes = nodeAssembler.assembleNodes()

  onEnvelope: (envelope) =>
    @datastore.get "#{envelope.flowId}/router/config", (error, routerConfig) =>
      senderNodeConfig = routerConfig[envelope.fromNodeId]

      _.each senderNodeConfig.linkedTo, (uuid) =>
        receiverNodeConfig = routerConfig[uuid]
        receiverNode = @nodes[receiverNodeConfig.type]

        receiverNode.onEnvelope
          flowId:  envelope.flowId
          message: envelope.message
          toNodeId:  uuid
          fromNodeId: envelope.fromNodeId
        , (error, envelope) =>
          @onEnvelope envelope

module.exports = Router
