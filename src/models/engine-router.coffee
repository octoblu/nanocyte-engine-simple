{Transform} = require 'stream'
_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:engine-router')
mergeStream = require 'merge-stream'

class EngineRouter extends Transform
  constructor: (@metadata, dependencies={})->
    super objectMode: true
    {NodeAssembler, @EngineRouterNode} = dependencies

    NodeAssembler ?= require './node-assembler'
    @EngineRouterNode ?= require './engine-router-node'

    @nodes = new NodeAssembler().assembleNodes()

  _transform: ({config, data, message}, enc, next) =>
    config = @_setupEngineNodeRoutes config
    toNodeIds = config[@metadata.fromNodeId]?.linkedTo || []

    if toNodeIds.length == 0
      @push null
      return next()

    debug "I'm a router about to route stuff"
    messageStreams = @_sendMessages toNodeIds, message, config

    messageStreams.on 'readable', =>
      envelope = messageStreams.read()
      return @push null unless envelope?
      router = new @EngineRouterNode

      newEnvelope =
        metadata: _.extend {}, envelope.metadata,
          toNodeId: 'router'
          transactionId: 0
        message: envelope.message

      messageStreams.add router.message(newEnvelope)

    messageStreams.on 'finish', => @end()

  _sendMessages: (toNodeIds, message, config) =>
    messageStreams = mergeStream()

    _.each toNodeIds, (toNodeId) =>
      messageStream = @_sendMessage(toNodeId, message, config)
      messageStreams.add messageStream if messageStream?

    messageStreams

  _sendMessage: (toNodeId, message, config) =>
    toNodeConfig = config[toNodeId]

    return console.error "toNodeConfig was not defined for node: #{toNodeId}" unless toNodeConfig?
    ToNodeClass = @nodes[toNodeConfig.type]

    return console.error "No registered type for '#{toNodeConfig.type}' for node #{toNodeId}" unless ToNodeClass?

    envelope =
      metadata: _.extend {}, @metadata,
        toNodeId: toNodeId
        fromNodeId: @metadata.fromNodeId
        transactionId: 0
      message: message

    debug "router is sending message:", envelope
    new ToNodeClass().message envelope

  _setupEngineNodeRoutes: (config)=>
    nodesToWireToOutput = _.filter config, (node) =>
      return node.type == 'engine-debug' || node.type == 'engine-pulse'

    _.each nodesToWireToOutput, (nodeToWireToOutput) =>
      nodeToWireToOutput.linkedTo.push 'engine-output'

    config

module.exports = EngineRouter
