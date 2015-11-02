_ = require 'lodash'
{Transform, PassThrough} = require 'stream'

debug = require('debug')('nanocyte-engine-simple:router')

MAX_MESSAGES = 1000
class Router extends Transform

  constructor: (@flowId, @instanceId, dependencies={})->
    super objectMode: true
    {NodeAssembler, @datastore, @lockManager} = dependencies

    @datastore ?= new (require './datastore')
    NodeAssembler ?= require './node-assembler'
    @lockManager ?= new (require './lock-manager')

    @nodeAssembler = new NodeAssembler()

  initialize: (callback=->) =>
    @liveNanocytes = 0
    @nodes = @nodeAssembler.assembleNodes()
    @datastore.hget @flowId, "#{@instanceId}/router/config", (error, @config) =>
      return callback(error) if error?
      return callback @_logError "config was not defined" unless @config?

      @_setupEngineNodeRoutes()

      @on 'end', => debug "Router finished!"
      @message = _.before @_unlimited_message, MAX_MESSAGES + 1
      callback()

  _unlimited_message: (envelope) =>
    return if @alreadyEnded

    unless @config?
      @_logError "no configuration"
      return @

    @push envelope

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
    toNodeConfig = @config[toNodeId]
    return @_logError "toNodeConfig was not defined for node: #{toNodeId}" unless toNodeConfig?

    ToNodeClass = @nodes[toNodeConfig.type]
    return @_logError "No registered type for '#{toNodeConfig.type}' for node #{toNodeId}" unless ToNodeClass?
    @lockManager.lock toNodeConfig.transactionGroupId, metadata.transactionId, (error, transactionId) =>
      return @_logError "lockManager unable to lock for node #{toNodeId}, with error: #{error}" if error?
      @liveNanocytes++

      envelope =
        metadata: _.extend {}, metadata,
          toNodeId: toNodeId
          fromNodeId: metadata.fromNodeId
          transactionId: transactionId
        message: message


      toNode = new ToNodeClass

      toNode.on 'readable', =>
        envelope = toNode.read()
        return @message envelope if envelope?
        @liveNanocytes--
        debug "#{toNodeId} finished. #{@liveNanocytes} remaining"
        @lockManager.unlock toNodeConfig.transactionGroupId, transactionId
        _.defer =>
          if @liveNanocytes == 0
            debug "Router is FINISHED. FINISHED, I TELL YOU"
            @closeRouter()

      toNode.message envelope

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

  closeRouter: =>
    debug "trying to close router"
    @end() unless @alreadyEnded
    @alreadyEnded = true


module.exports = Router
