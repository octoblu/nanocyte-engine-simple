_ = require 'lodash'
{Writable} = require 'stream'
mergeStream = require 'merge-stream'
debug = require('debug')('nanocyte-engine-simple:router')

class Router extends Writable

  constructor: (@flowId, @instanceId, dependencies={})->
    super objectMode: true
    @routeCount = 0
    {NodeAssembler, @datastore} = dependencies
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
        errorMsg = 'router.coffee: config was not defined'
        console.error errorMsg
        return callback new Error errorMsg

      @nanocyteStreams.pipe @
      @on 'finish', => console.log "ROUTER IS DEAD"

      callback()

  _unlimited_message: (envelope) =>
    return console.error "Error: no configuration for flow" unless @config?

    toNodeIds = @_getToNodeIds envelope.metadata.nodeId
    @_sendMessages toNodeIds, envelope

  _sendMessages: (toNodeIds, envelope) =>
    _.each toNodeIds, (toNodeId) =>
      @_sendMessage toNodeId, envelope

  _getToNodeIds: (fromNodeId) =>
    senderNodeConfig = @config[fromNodeId]
    unless senderNodeConfig?
      console.error 'router.coffee: senderNodeConfig was not defined'
      return []

    return senderNodeConfig.linkedTo || []

  _sendMessage: (toNodeId, {metadata, message}) =>
    debug "sendMessage", toNodeId, metadata, message
    toNodeConfig = @config[toNodeId]
    return console.error 'router.coffee: toNodeConfig was not defined' unless toNodeConfig?

    toNode = @nodes[toNodeConfig.type]
    return console.error "router.coffee: No registered type for '#{toNodeConfig.type}'" unless toNode?
    
    envelope =
      metadata: _.extend {}, metadata, nodeId: toNodeId
      message: message

    responseStream = toNode.message envelope

    # responseStream.on 'end', =>
    #   debug "responseStream finished for #{toNodeId}"
    # @nanocyteStreams.add responseStream

module.exports = Router
