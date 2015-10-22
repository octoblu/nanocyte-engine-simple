_ = require 'lodash'
{Writable} = require 'stream'
mergeStream = require 'merge-stream'
debug = require('debug')('nanocyte-engine-simple:router')

class Router extends Writable

  constructor: (@flowId, @instanceId, dependencies={})->
    super objectMode: true
    @routeCount = 0
    {NodeAssembler, @datastore, @lockManager} = dependencies
    @datastore ?= new (require './datastore')
    NodeAssembler ?= require './node-assembler'

    @nodeAssembler = new NodeAssembler()
    @nanocyteStreams = mergeStream()

    @message = _.before @_unlimited_message, 1000

  initialize: (callback=->) =>
    @nodes = @nodeAssembler.assembleNodes()

    @datastore.hget @flowId, "#{@instanceId}/router/config", (error, @config) =>
      return callback(error) if error?

      unless @config?
        errorMsg = "router.coffee: config was not defined for flow: #{@flowId}, instance: #{@instanceId}"
        console.error errorMsg
        return callback new Error errorMsg

      @nanocyteStreams.pipe @

      callback()

  _unlimited_message: (envelope) =>
    return console.error "Error: no configuration for flow: #{@flowId}, instance: #{@instanceId}" unless @config?

    toNodeIds = @_getToNodeIds envelope.metadata.nodeId
    @_sendMessages toNodeIds, envelope

  _getToNodeIds: (fromNodeId) =>
    senderNodeConfig = @config[fromNodeId]
    unless senderNodeConfig?
      console.error 'router.coffee: senderNodeConfig was not defined'
      return []

    return senderNodeConfig.linkedTo || []

  _sendMessages: (toNodeIds, envelope) =>
    _.each toNodeIds, (toNodeId) =>
      @_sendMessage toNodeId, envelope

  _sendMessage: (toNodeId, {metadata, message}) =>
    debug "from: #{metadata.nodeId}, sendMessage to: #{toNodeId}", metadata, message

    toNodeConfig = @config[toNodeId]
    return console.error "router.coffee: toNodeConfig was not defined for node: #{toNodeId} in flow: #{@flowId}, instance: #{@instanceId}" unless toNodeConfig?

    ToNodeClass = @nodes[toNodeConfig.type]
    return console.error "router.coffee: No registered type for '#{toNodeConfig.type}' for node #{toNodeId} in flow: #{@flowId}, instance: #{@instanceId}" unless ToNodeClass?
    toNode = new ToNodeClass

    @lockManager.lock toNodeConfig.transactionGroupId, metadata.transactionId, (error, transactionId) =>
      debug "instantiated type #{toNodeConfig.type} of class #{ToNodeClass}"
      return console.error "router.coffee: lockManager unable to lock for node #{toNodeId} in flow: #{@flowId}, instance: #{@instanceId}, with error: #{error}" if error?

      envelope =
        metadata: _.extend {}, metadata, nodeId: toNodeId, transactionId: transactionId
        message: message

      responseStream = toNode.message envelope
      responseStream.on 'end', =>
        debug "responseStream finished for #{toNodeId}"
        @lockManager.unlock toNodeConfig.transactionGroupId, transactionId

      @nanocyteStreams.add responseStream

  _write: (envelope, enc, next) =>
    debug "Router is routing message:", envelope
    @message envelope
    next()

module.exports = Router
