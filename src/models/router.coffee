_ = require 'lodash'
{Writable} = require 'stream'
mergeStream = require 'merge-stream'
debugStream = require('debug-stream')('nanocyte-engine-router')

debug = require('debug')('nanocyte-engine-router')

class Router extends Writable
  constructor: (@flowId, @instanceId, dependencies={})->
    super objectMode: true
    @routeCount = 0
    {NodeAssembler, @datastore} = dependencies
    @datastore ?= new (require './datastore')
    NodeAssembler ?= require './node-assembler'

    @nodeAssembler = new NodeAssembler()
    @nanocyteStreams = mergeStream()

    @onEnvelope = _.before @_unlimited_onEnvelope, 100

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

  _unlimited_onEnvelope: ({metadata, message}) =>
    debug "onEnvelope", metadata, message
    toNodeIds = @getToNodeIds metadata.fromNodeId

    envelope =
      metadata:
        fromNodeId: metadata.fromNodeId
      message: message

    @sendEnvelopes(toNodeIds, envelope)

  getToNodeIds: (fromNodeId) =>
    senderNodeConfig = @config[fromNodeId]
    unless senderNodeConfig?
      console.error 'router.coffee: senderNodeConfig was not defined'
      return []

    return senderNodeConfig.linkedTo || []

  sendEnvelopes: (toNodeIds, envelope) =>
    _.each toNodeIds, (toNodeId) =>
      console.log "starting responseStream for #{toNodeId}"
      responseStream = @sendEnvelope toNodeId, envelope
      responseStream.on 'end', => console.log "response Stream died for #{toNodeId}"
      @nanocyteStreams.add responseStream

  sendEnvelope: (toNodeId, {metadata, message}) =>
    debug "sendMessage", toNodeId, metadata, message
    toNodeConfig = @config[toNodeId]
    return console.error 'router.coffee: toNodeConfig was not defined' unless toNodeConfig?

    toNode = @nodes[toNodeConfig.type]
    return console.error "router.coffee: No registered type for '#{toNodeConfig.type}'" unless toNode?

    envelope =
      metadata:
        flowId: @flowId
        instanceId: @instanceId
        nodeId: toNodeId
      message: message

    return toNode.onEnvelope envelope

  _write: (envelope, enc, next) =>
    @onEnvelope envelope
    next()

module.exports = Router
