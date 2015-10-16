_ = require 'lodash'
{Writable} = require 'stream'
mergeStream = require 'merge-stream'

debug = require('debug')('nanocyte-engine-router')

class Router extends Writable
  constructor: (@flowId, @instanceId, dependencies={})->
    super objectMode: true
    {NodeAssembler, @datastore} = dependencies
    @datastore ?= new (require './datastore')
    NodeAssembler ?= require './node-assembler'

    @nodeAssembler = new NodeAssembler()
    @nanocyteStreams = mergeStream()

  initialize: (callback=->) =>
    @nodes = @nodeAssembler.assembleNodes()

    @datastore.hget @flowId, "#{@instanceId}/router/config", (error, @config) =>
      return callback(error) if error?

      unless @config?
        errorMsg = 'router.coffee: config was not defined'
        console.error errorMsg
        return callback new Error errorMsg

      @nanocyteStreams.pipe @
      callback()

  onEnvelope: (envelope, callback) =>
    debug "onEnvelope", envelope
    {metadata, message} = envelope
    toNodeIds = @getToNodeIds metadata.fromNodeId

    @sendMessages(toNodeIds, message)

  getToNodeIds: (fromNodeId) =>
    senderNodeConfig = @config[fromNodeId]
    unless senderNodeConfig?
      console.error 'router.coffee: senderNodeConfig was not defined'
      return []

    return senderNodeConfig.linkedTo || []

  sendMessages: (toNodeIds, message) =>
    debug "sendMessages", toNodeIds, message
    _.each toNodeIds, (toNodeId) =>
      @responseStream = @sendMessage toNodeId, message
      @nanocyteStreams.add @responseStream

  sendMessage: (toNodeId, message) =>
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

  _write: (envelope, callback) =>
    @onEnvelope envelope, callback

module.exports = Router
