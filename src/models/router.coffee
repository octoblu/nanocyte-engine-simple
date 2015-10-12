_ = require 'lodash'
async = require 'async'
debug = require('debug')('nanocyte-engine-simple:router')
Benchmark = require './benchmark'
LockManager = require './lock-manager'

class Router
  constructor: (dependencies={}) ->
    {NodeAssembler, @datastore, @lockManager} = dependencies

    @lockManager ?= new LockManager
    @datastore ?= new (require './datastore')

    NodeAssembler ?= require './node-assembler'
    nodeAssembler = new NodeAssembler()
    @nodes = nodeAssembler.assembleNodes()

    @i = 0
    @sendEnvelope = _.before 1000, @_unlimited_sendEnvelope

  onEnvelope: (envelope) =>
    {transactionGroupId, transactionId, flowId,instanceId,toNodeId,fromNodeId,message} = envelope
    @lockManager.lock transactionGroupId, transactionId, (error, transactionId) =>
      debug 'onEnvelope', envelope
      envelope.transactionId = transactionId

      @datastore.hget flowId, "#{instanceId}/router/config", (error, routerConfig) =>
        return console.error 'router.coffee: routerConfig was not defined' unless routerConfig?
        senderNodeConfig = routerConfig[fromNodeId]
        return console.error 'router.coffee: senderNodeConfig was not defined' unless senderNodeConfig?

        _.each senderNodeConfig.linkedTo, (uuid) =>
          @sendEnvelope uuid, envelope, routerConfig

  _unlimited_sendEnvelope: (uuid, envelope, routerConfig) =>
    debug 'sendEnvelope', @i
    @i += 1

    {flowId,instanceId,toNodeId,fromNodeId,transactionGroupId,transactionId,message} = envelope
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
      transactionGroupId: transactionGroupId
      transactionId: transactionId
    , (error, envelope) =>
      return unless envelope?
      debug benchmark.toString()
      _.defer @onEnvelope, envelope
    , (error, envelope) =>
      {transactionGroupId, transactionId} = envelope
      @lockManager.unlock transactionGroupId, transactionId

module.exports = Router
