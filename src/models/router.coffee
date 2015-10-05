_ = require 'lodash'
async = require 'async'
debug = require('debug')('nanocyte-engine-simple:router')
NodeAssembler = require './node-assembler'
Benchmark = require './benchmark'

class Router
  constructor: (dependencies={}) ->
    {nodeAssembler,@datastore} = dependencies

    @datastore ?= new (require './datastore')

    nodeAssembler ?= new NodeAssembler()
    @nodes = nodeAssembler.assembleNodes()

  onEnvelope: (envelope) =>
    debug 'onEnvelope', envelope
    {flowId,instanceId,toNodeId,fromNodeId,message} = envelope

    @datastore.hget flowId, "#{instanceId}/router/config", (error, routerConfig) =>
      return console.error 'router.coffee: routerConfig was not defined' unless routerConfig?
      senderNodeConfig = routerConfig[fromNodeId]
      return console.error 'router.coffee: senderNodeConfig was not defined' unless senderNodeConfig?

      _.each senderNodeConfig.linkedTo, (uuid) =>
        debug uuid
        receiverNodeConfig = routerConfig[uuid]
        return console.error 'router.coffee: receiverNodeConfig was not defined' unless receiverNodeConfig?

        receiverNode = @nodes[receiverNodeConfig.type]
        return console.error "router.coffee: No registered type for '#{receiverNodeConfig.type}'" unless receiverNode?

        benchmark = new Benchmark label: receiverNodeConfig.type
        _.defer receiverNode.onEnvelope,
          flowId:      flowId
          instanceId:  instanceId
          message:     message
          toNodeId:    uuid
          fromNodeId:  fromNodeId
        , (error, envelope) =>
          return unless envelope?
          debug benchmark.toString()
          _.defer @onEnvelope, envelope

module.exports = Router
