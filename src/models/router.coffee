_ = require 'lodash'
{PassThrough} = require 'stream'
mergeStream = require 'merge-stream'
debug = require('debug')('nanocyte-engine-simple:router')
debugStream = require('debug-stream')('nanocyte-engine-simple:router')

class Router extends PassThrough

  constructor: (@flowId, @instanceId, dependencies={})->
    super objectMode: true
    @routeCount = 0
    {NodeAssembler, @datastore, @lockManager} = dependencies

    @datastore ?= new (require './datastore')
    NodeAssembler ?= require './node-assembler'
    @lockManager ?= new (require './lock-manager')

    @nodeAssembler = new NodeAssembler()
    @nanocyteStreams = mergeStream()

    @message = _.before @_unlimited_message, 1000

  initialize: (callback=->) =>
    @nodes = @nodeAssembler.assembleNodes()

    @datastore.hget @flowId, "#{@instanceId}/router/config", (error, @config) =>
      return callback(error) if error?

      unless @config?
        errorMsg = @_logError "config was not defined"
        return callback new Error errorMsg

      @_setupEngineNodeRoutes()

      @nanocyteStreams
        .pipe debugStream 'nanocyte-stream'
        .pipe @

      callback()

  _unlimited_message: (envelope) =>
    return @_logError "no configuration" unless @config?

    toNodeIds = @_getToNodeIds envelope.metadata.fromNodeId
    @_sendMessages toNodeIds, envelope
    return @

  _getToNodeIds: (fromNodeId) =>
    senderNodeConfig = @config[fromNodeId]
    unless senderNodeConfig?
      @_logError "senderNodeConfig was not defined for node: #{fromNodeId} in flow: #{@flowId}, instance: #{@instanceId}"
      return []

    return senderNodeConfig.linkedTo || []

  _sendMessages: (toNodeIds, envelope) =>
    debug "sending a message to", toNodeIds
    _.each toNodeIds, (toNodeId) =>
      @_sendMessage toNodeId, envelope

  _sendMessage: (toNodeId, {metadata, message}) =>
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

      @nanocyteStreams.add responseStream

  _write: (envelope, enc, next) =>
    @message envelope
    next()

  _setupEngineNodeRoutes: =>
    #this should be _.pick with a predicate so we can get the key as well
    outputNode = _.find @config, type: 'engine-output'
    return unless outputNode?

    nodesToWireToOutput = _.filter @config, type: 'engine-debug'
    _.each nodesToWireToOutput, (nodeToWireToOutput) =>
      nodeToWireToOutput.linkedTo.push 'engine-output'

    debug "config is now:", @config

  _logError: (errorString) =>
    logErrorString = "router.coffee: #{errorString} in flow: #{@flowId}, instance: #{@instanceId}"
    console.error logErrorString
    logErrorString

module.exports = Router
