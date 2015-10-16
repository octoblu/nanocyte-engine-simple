_ = require 'lodash'
async = require 'async'
debug = require('debug')('nanocyte-engine-simple:router')
Benchmark = require './benchmark'
LockManager = require './lock-manager'
ProcessCountManager = require './process-count-manager'

class Router
  constructor: (dependencies={}) ->
    {NodeAssembler, @datastore, @lockManager} = dependencies
    @lockManager ?= new LockManager
    @datastore ?= new (require './datastore')

    NodeAssembler ?= require './node-assembler'
    nodeAssembler = new NodeAssembler()
    @nodes = nodeAssembler.assembleNodes()

    @sendEnvelope = _.before 1000, @_unlimited_sendEnvelope

  onEnvelope: (envelope, endCallback=->) =>
    @processCountManager = new ProcessCountManager endCallback, class: 'router'
    @processCountManager.up()
    @_onEnvelope envelope, =>
      @processCountManager.down()
      @processCountManager.checkZero()

  _onEnvelope: (envelope, callback) =>
    @processCountManager.up()
    {flowId,instanceId,toNodeId,fromNodeId,message} = envelope
    @datastore.hget flowId, "#{instanceId}/router/config", (error, routerConfig) =>
      return console.error 'router.coffee: routerConfig was not defined' unless routerConfig?
      senderNodeConfig = routerConfig[fromNodeId]
      return console.error 'router.coffee: senderNodeConfig was not defined' unless senderNodeConfig?

      eachCallback = (uuid, next) =>
        @sendEnvelope uuid, envelope, routerConfig, (error) =>
          next error

      endEachCallback = (error) =>
        console.error error if error?
        @processCountManager.down()
        @processCountManager.checkZero()
        callback null

      async.each senderNodeConfig.linkedTo, eachCallback, endEachCallback

  _unlimited_sendEnvelope: (uuid, envelope, routerConfig, next) =>
    {flowId,instanceId,toNodeId,fromNodeId,transactionId,message} = envelope

    receiverNodeConfig = routerConfig[uuid]
    return next 'router.coffee: receiverNodeConfig was not defined' unless receiverNodeConfig?

    receiverNode = @nodes[receiverNodeConfig.type]
    return next "router.coffee: No registered type for '#{receiverNodeConfig.type}'" unless receiverNode?

    transactionGroupId = receiverNodeConfig.transactionGroupId

    @processCountManager.up()
    @lockManager.lock transactionGroupId, transactionId, (error, transactionId) =>
      debug 'onEnvelope', envelope

      benchmark = new Benchmark label: receiverNodeConfig.type
      _.defer receiverNode.onEnvelope,
        flowId:      flowId
        instanceId:  instanceId
        message:     message
        toNodeId:    uuid
        fromNodeId:  fromNodeId
        transactionId: transactionId
      , (error, envelope) =>
        return unless envelope?
        debug benchmark.toString()
        _.defer @_onEnvelope, envelope, =>
      , (error, envelope) =>
        _.defer =>
          {transactionId} = envelope
          @processCountManager.down()
          @lockManager.unlock transactionGroupId, transactionId
          next()

module.exports = Router
