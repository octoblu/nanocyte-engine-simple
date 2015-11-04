{Transform, PassThrough} = require 'stream'
_ = require 'lodash'
async = require 'async'
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

    @messageStreams = mergeStream()

    @queue = async.queue @_doWork, 1

    unless @nodes?
      NodeAssembler = require './node-assembler'
      @nodes = new NodeAssembler().assembleNodes()

  _transform: ({config, data, message}, enc) =>
    return @push null if @messageCount > MAX_MESSAGE_COUNT
    config = @_setupEngineNodeRoutes config
    toNodeIds = config[@metadata.fromNodeId]?.linkedTo || []

    if toNodeIds.length == 0
      @push null

    debug "Incoming message from: #{@metadata.fromNodeId}, to: #{toNodeIds}"

    messageStreams = @_sendMessages toNodeIds, message, config

    messageStreams.on 'readable', =>
      envelope = messageStreams.read()
      return @push null unless envelope?

      router = new @EngineRouterNode nodes: @nodes
      messageStreams.add router.stream

      @queue.push router: router, envelope: envelope

    messageStreams.on 'finish', => @end()

  _doWork: (task, callback) =>
    {router,envelope} = task
    newEnvelope =
      metadata: _.extend {}, envelope.metadata, toNodeId: 'router', messageCount: @messageCount
      message: envelope.message

    router.message newEnvelope

    router.stream.on 'end', => callback()

  _sendMessages: (toNodeIds, message, config) =>
    async.eachSeries toNodeIds, (toNodeId, done) =>
      messageStream = @_sendMessage toNodeId, message, config
      @messageStreams.add messageStream if messageStream?
      messageStream.on 'end', => done()

    return @messageStreams

  _sendMessage: (toNodeId, message, config, metadata={}) =>
    sendMessageStream = new PassThrough objectMode: true
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

      sendMessageStream.on 'end', => @lockManager.unlock toNodeConfig.transactionGroupId, transactionId

      @_protect =>
        messageStream = toNode.stream
        toNode.message envelope
        messageStream.pipe sendMessageStream
      , (error) =>
        @_sendError toNodeId, error, config
        sendMessageStream.push null

    return sendMessageStream

  _setupEngineNodeRoutes: (config)=>
    nodesToWireToOutput = _.filter config, (node) =>
      return node.type == 'engine-debug' || node.type == 'engine-pulse'

    _.each nodesToWireToOutput, (nodeToWireToOutput) =>
      nodeToWireToOutput.linkedTo.push 'engine-output'

    return config

  _protect: (run, onError) ->
    domain = require('domain').create()
    domain.on 'error', onError
    domain.run run
    return

  _sendError: (fromNodeId, error, config) =>
    if _.startsWith fromNodeId, 'engine-'
      fromNodeId = @metadata.fromNodeId
    console.error error.stack

    metadata = _.extend {}, @metadata, msgType: 'error', fromNodeId: fromNodeId, toNodeId: 'engine-debug', messageCount: @messageCount++
    messageStream = @_sendMessage 'engine-debug', {message: error.message}, config, metadata
    @messageStreams.add messageStream

module.exports = EngineRouter
