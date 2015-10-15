_ = require 'lodash'
async = require 'async'
debug = require('debug')('nanocyte-engine-simple:router')
Benchmark = require './benchmark'
LockManager = require './lock-manager'
{Writable} = require 'stream'

class Router extends Writable
  constructor: (dependencies={}) ->
    super objectMode: true
    {NodeAssembler, @datastore, @lockManager} = dependencies

    @lockManager ?= new LockManager
    @datastore ?= new (require './datastore')

    NodeAssembler ?= require './node-assembler'
    nodeAssembler = new NodeAssembler()
    @nodes = nodeAssembler.assembleNodes()
    @sendEnvelope = _.before 1000, @_unlimited_sendEnvelope

  _write: (envelope, enc, next) =>
    {flowId,instanceId,toNodeId,fromNodeId,message} = envelope

    @datastore.hget flowId, "#{instanceId}/router/config", (error, routerConfig) =>
      next()
      return console.error 'router.coffee: routerConfig was not defined' unless routerConfig?
      senderNodeConfig = routerConfig[fromNodeId]
      return console.error 'router.coffee: senderNodeConfig was not defined' unless senderNodeConfig?

      _.each senderNodeConfig.linkedTo, (uuid) =>
        @sendEnvelope uuid, envelope, routerConfig

  _unlimited_sendEnvelope: (uuid, envelope, routerConfig) =>
    {flowId,instanceId,toNodeId,fromNodeId,transactionId,message} = envelope

    receiverNodeConfig = routerConfig[uuid]
    return console.error 'router.coffee: receiverNodeConfig was not defined' unless receiverNodeConfig?

    ReceiverNode = @nodes[receiverNodeConfig.type]
    return console.error "router.coffee: No registered type for '#{receiverNodeConfig.type}'" unless ReceiverNode?

    transactionGroupId = receiverNodeConfig.transactionGroupId

    @lockManager.lock transactionGroupId, transactionId, (error, transactionId) =>
      console.log "BEGIN #{transactionId}, #{receiverNodeConfig.type}"
      debug 'onEnvelope', envelope

      receiverNode = ReceiverNode()

      receiverNode.write
        flowId:      flowId
        instanceId:  instanceId
        message:     message
        toNodeId:    uuid

      receiverNode.pipe @, end: false

      receiverNode.on 'end', =>
        console.log "END #{transactionId}, #{receiverNodeConfig.type}"
        @lockManager.unlock transactionGroupId, transactionId

module.exports = Router
