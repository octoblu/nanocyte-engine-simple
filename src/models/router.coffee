_ = require 'lodash'
NodeAssembler = require './node-assembler'

class Router
  constructor: (dependencies={}) ->
    {nodeAssembler,@datastore} = dependencies

    @datastore ?= require '../handlers/datastore-handler'

    nodeAssembler ?= new NodeAssembler()
    @nodes = nodeAssembler.assembleNodes()

  onEnvelope: (envelope) =>
    @datastore.get "#{envelope.flowId}/b028a0f0-5cca-11e5-ba53-cbe60492eee3/router/config", (error, routerConfig) =>
      senderNodeConfig = routerConfig[envelope.fromNodeId]

      _.each senderNodeConfig.linkedTo, (uuid) =>
        debugger
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
