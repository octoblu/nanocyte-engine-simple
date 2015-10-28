_ = require 'lodash'
{Transform, PassThrough} = require 'stream'
mergeStream = require 'merge-stream'
debug = require('debug')('nanocyte-engine-simple:router')
debugStream = require('debug-stream')('nanocyte-engine-simple:router:nanocyte-stream')

MAX_MESSAGES = 300
class Router extends Transform

  constructor: (@flowId, @instanceId, dependencies={})->
    super objectMode: true
    {NodeAssembler, @datastore, @lockManager} = dependencies

    @datastore ?= new (require './datastore')
    NodeAssembler ?= require './node-assembler'
    @lockManager ?= new (require './lock-manager')

    @nodeAssembler = new NodeAssembler()
    @nanocyteStreams = mergeStream()

  initialize: (callback=->) =>
    @nodes = @nodeAssembler.assembleNodes()
    @messageCount = 0
    @datastore.hget @flowId, "#{@instanceId}/router/config", (error, @config) =>
      return callback(error) if error?
      return callback @_logError "config was not defined" unless @config?

      @_setupEngineNodeRoutes()

      @nanocyteStreams.on 'readable', =>
        envelope = @nanocyteStreams.read()
        return @end() unless envelope?
        @message envelope
        @push envelope

      @on 'end', => debug "Router finished!"

      callback()

  message: (envelope) =>
    return @ if ++@messageCount > MAX_MESSAGES

    unless @config?
      @_logError "no configuration"
      return @

    toNodeIds = @_getToNodeIds envelope.metadata.fromNodeId
    @_sendMessages toNodeIds, envelope
    return @

  _getToNodeIds: (fromNodeId) =>
    senderNodeConfig = @config[fromNodeId]
    unless senderNodeConfig?
      @_logError "senderNodeConfig was not defined for node: #{fromNodeId}"
      return []

    return senderNodeConfig.linkedTo || []

  _sendMessages: (toNodeIds, envelope) =>
    debug "sending a message to", toNodeIds
    _.each toNodeIds, (toNodeId) =>
      @_sendMessage toNodeId, envelope

  _sendMessage: (toNodeId, {metadata, message}) =>
    stream = new PassThrough objectMode: true

    toNodeConfig = @config[toNodeId]
    return @_logError "toNodeConfig was not defined for node: #{toNodeId}" unless toNodeConfig?

    ToNodeClass = @nodes[toNodeConfig.type]
    return @_logError "No registered type for '#{toNodeConfig.type}' for node #{toNodeId}" unless ToNodeClass?
    toNode = new ToNodeClass

    @lockManager.lock toNodeConfig.transactionGroupId, metadata.transactionId, (error, transactionId) =>
      return @_logError "lockManager unable to lock for node #{toNodeId}, with error: #{error}" if error?

      envelope =
        metadata: _.extend {}, metadata,
          toNodeId: toNodeId
          fromNodeId: metadata.fromNodeId
          transactionId: transactionId
        message: message

      responseStream = toNode.message envelope

      responseStream.on 'end', =>
        debug "responseStream finished for #{toNodeId}"
        @lockManager.unlock toNodeConfig.transactionGroupId, transactionId

      responseStream.pipe stream

    @nanocyteStreams.add stream

  _transform: (envelope, enc, next) =>
    @message envelope
    @push envelope
    next()

  _setupEngineNodeRoutes: =>
    outputNodeId = _.findKey @config, type: 'engine-output'
    return unless outputNodeId?

    nodesToWireToOutput = _.filter @config, (node) =>
      return node.type == 'engine-debug' || node.type == 'engine-pulse'

    _.each nodesToWireToOutput, (nodeToWireToOutput) =>
      nodeToWireToOutput.linkedTo.push outputNodeId unless _.contains nodeToWireToOutput.linkedTo,outputNodeId

    debug "config is now:", @config

  _logError: (errorString) =>
    logErrorString = "router.coffee: #{errorString} in flow: #{@flowId}, instance: #{@instanceId}"
    console.error logErrorString
    new Error logErrorString

module.exports = Router
