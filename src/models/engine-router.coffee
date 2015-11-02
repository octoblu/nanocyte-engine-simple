{Transform} = require 'stream'
_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:engine-router')
mergeStream = require 'merge-stream'
MAX_MESSAGE_COUNT = 1000

class EngineRouter extends Transform
  constructor: (@metadata, dependencies={})->
    super objectMode: true
    {@messageCount} = @metadata
    @messageCount ?= 0
    {@EngineRouterNode, @nodes, @lockManager} = dependencies

    @lockManager ?= new (require './lock-manager')
    @EngineRouterNode ?= require './engine-router-node'

    unless @nodes?
      NodeAssembler = require './node-assembler'
      @nodes = new NodeAssembler().assembleNodes()

  _transform: ({config, data, message}, enc, next) =>
    return @push null if @messageCount > MAX_MESSAGE_COUNT
    config = @_setupEngineNodeRoutes config
    toNodeIds = config[@metadata.fromNodeId]?.linkedTo || []

    if toNodeIds.length == 0
      @push null
      return next()

    debug "Incoming message from: #{@metadata.fromNodeId}, to: #{toNodeIds}"

    messageStreams = @_sendMessages toNodeIds, message, config

    messageStreams.on 'readable', =>
      envelope = messageStreams.read()
      return @push null unless envelope?
      router = new @EngineRouterNode nodes: @nodes
      if envelope.metadata.msgType == 'error'
        @_sendError envelope, config
        @push null
        return

      newEnvelope =
        metadata: _.extend {}, envelope.metadata, toNodeId: 'router', messageCount: @messageCount
        message: envelope.message

      messageStreams.add router.message(newEnvelope)

    messageStreams.on 'finish', => @end()

  _sendMessages: (toNodeIds, message, config) =>
    messageStreams = mergeStream()

    _.each toNodeIds, (toNodeId) =>
      messageStream = @_sendMessage toNodeId, message, config
      messageStreams.add messageStream if messageStream?

    messageStreams

  _sendError: (toNodeId, error, config) =>
    metadata = _.extend {}, @metadata, msgType: 'error', fromNodeId: toNodeId
    message =
      message: error.message
      msgType: 'error'

    @_sendMessage 'engine-debug', message, config, metadata

  _sendMessage: (toNodeId, message, config, metadata={}) =>
    debug 'sending message', JSON.stringify(message,null,2)
    toNodeConfig = config[toNodeId]

    return console.error "toNodeConfig was not defined for node: #{toNodeId}" unless toNodeConfig?
    ToNodeClass = @nodes[toNodeConfig.type]

    return console.error "No registered type for '#{toNodeConfig.type}' for node #{toNodeId}" unless ToNodeClass?
    toNode = new ToNodeClass()

    @lockManager.lock toNodeConfig.transactionGroupId, @metadata.transactionId, (error, transactionId) =>

      newMetadata =
        toNodeId: toNodeId
        fromNodeId: @metadata.fromNodeId
        transactionId: transactionId
        messageCount: ++@messageCount

      envelope =
        metadata: _.extend {}, @metadata, newMetadata, metadata
        message: message

      debug "messageCount: #{@messageCount}"
      toNode.on 'end', => @lockManager.unlock toNodeConfig.transactionGroupId, transactionId
      toNode.on 'error', (error) => @_sendError toNodeId, error, config

      toNode.message envelope
    toNode

  _setupEngineNodeRoutes: (config)=>
    nodesToWireToOutput = _.filter config, (node) =>
      return node.type == 'engine-debug' || node.type == 'engine-pulse'

    _.each nodesToWireToOutput, (nodeToWireToOutput) =>
      nodeToWireToOutput.linkedTo.push 'engine-output'

    config

module.exports = EngineRouter
