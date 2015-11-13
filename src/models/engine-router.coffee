{Transform, PassThrough} = require 'stream'
_ = require 'lodash'
async = require 'async'
debug = require('debug')('nanocyte-engine-simple:engine-router')
mergeStream = require 'merge-stream'

class EngineRouter extends Transform
  constructor: (@metadata, dependencies={})->
    super objectMode: true
    {@EngineRouterNode, @nodes, @lockManager} = dependencies
    @lockManager ?= new (require './lock-manager')
    @EngineRouterNode ?= require './engine-router-node'

    @messageStreams = mergeStream()
    @queue = async.queue @_doWork, 1

    unless @nodes?
      NodeAssembler = require './node-assembler'
      @nodes = new NodeAssembler().assembleNodes()

  _transform: ({config, data, message}, enc, next) =>

    config = @_setupEngineNodeRoutes config
    fromNodeConfig = config[@metadata.fromNodeId]

    toNodeIds = fromNodeConfig?.linkedTo || []
    toNodeIds = ['engine-debug'] if @metadata.msgType == 'error' and @metadata.fromNodeId != 'engine-debug'

    fromNodeName = fromNodeConfig?.type
    toNodeNames = _.map toNodeIds, (toNodeId) =>
      toNodeConfig = config[toNodeId]
      "#{toNodeConfig?.type}(#{toNodeId})"

    unless _.isEmpty toNodeNames
      debug "Incoming message #{JSON.stringify message}"
      debug "  from: #{fromNodeName}(#{@metadata.fromNodeId})"
      debug "  to: #{toNodeNames}"

    return @shutdown() if toNodeIds.length == 0

    messageStreams = @_sendMessages toNodeIds, message, config

    messageStreams.on 'finish', @shutdown
    messageStreams.on 'readable', =>
      return if @shuttingDown

      envelope = messageStreams.read()
      return @shutdown() unless envelope?

      @push envelope.message
      router = new @EngineRouterNode nodes: @nodes, lockManager: @lockManager
      messageStreams.add router.stream

      @queue.push router: router, envelope: envelope

  _doWork: (task, callback) =>
    {router,envelope} = task
    newEnvelope =
      metadata: _.extend {}, envelope.metadata, toNodeId: 'router'
      message: envelope.message

    router.stream.on 'finish', => callback()
    router.stream.on 'error', (error) => @forwardError envelope.metadata.fromNodeId, error

    router.message newEnvelope

  _sendMessages: (toNodeIds, message, config) =>
    toNodeIds = _.sortBy toNodeIds, (toNodeId) =>
        return 0 if _.startsWith toNodeId, 'engine-'
        return 1

    async.each toNodeIds, (toNodeId, done) =>
      messageStream = @_sendMessage toNodeId, message, config
      return done() unless messageStream?

      @messageStreams.add messageStream
      messageStream.on 'finish', => done()

    return @messageStreams

  _sendMessage: (toNodeId, message, config, metadata={}) =>
    toNodeConfig = config[toNodeId]
    return console.error "toNodeConfig was not defined for node: #{toNodeId}" unless toNodeConfig?

    ToNodeClass = @nodes[toNodeConfig.type]
    return console.error "No registered type for '#{toNodeConfig.type}' for node #{toNodeId}" unless ToNodeClass?

    transactionGroupId = toNodeConfig.transactionGroupId
    if toNodeId == 'engine-data'
      fromNodeConfig = config[@metadata.fromNodeId]
      transactionGroupId = fromNodeConfig.transactionGroupId

    passThrough = new PassThrough objectMode: true

    @lockManager.lock transactionGroupId, @metadata.transactionId, (error, transactionId) =>
      toNode = new ToNodeClass()

      newMetadata =
        toNodeId: toNodeId
        fromNodeId: @metadata.fromNodeId
        transactionId: transactionId

      envelope =
        metadata: _.extend {}, @metadata, newMetadata, metadata
        message: message

      toNode.stream.on 'finish', =>
        debug "unlocking #{toNodeConfig.type}(#{toNodeId}) #{transactionGroupId} #{transactionId}"
        @lockManager.unlock transactionGroupId, transactionId
      toNode.stream.on 'error', (error) => @forwardError toNodeId, error
      toNode.message envelope
      toNode.stream.pipe passThrough

    return passThrough

  _setupEngineNodeRoutes: (config) =>
    nodesToWireToOutput = _.filter config, (node) =>
      return node.type == 'engine-debug' || node.type == 'engine-pulse'

    _.each nodesToWireToOutput, (nodeToWireToOutput) =>
      nodeToWireToOutput.linkedTo.push 'engine-batch'

    config['engine-batch'] = type: 'engine-batch'
    return config

  forwardError: (nodeId, error, config) =>
    nodeId = @metadata.fromNodeId if _.startsWith nodeId, 'engine-'
    error.nodeId = nodeId unless error.nodeId?

    @shutdown()
    @emit 'error', error

  shutdown: =>
    return if @shuttingDown
    @shuttingDown = true
    @queue.kill()
    @push null

module.exports = EngineRouter
