_ = require 'lodash'
NodeAssembler = require './node-assembler'

class Router
  constructor: (dependencies={}) ->
    {nodeAssembler,@datastore} = dependencies

    @datastore ?= require '../handlers/datastore-handler'

    nodeAssembler ?= new NodeAssembler()
    @nodes = nodeAssembler.assembleNodes()

  onEnvelope: (envelope) =>
    {flowId,instanceId,toNodeId,fromNodeId,message} = envelope

    @datastore.get "#{flowId}/#{instanceId}/router/config", (error, routerConfig) =>
      senderNodeConfig = routerConfig[fromNodeId]

      _.each senderNodeConfig.linkedTo, (uuid) =>
        receiverNodeConfig = routerConfig[uuid]
        receiverNode = @nodes[receiverNodeConfig.type]

        receiverNode.onEnvelope
          flowId:      flowId
          instanceId:  instanceId
          message:     message
          toNodeId:    uuid
          fromNodeId:  fromNodeId
        , (error, envelope) =>
          @onEnvelope envelope

module.exports = Router
