_ = require 'lodash'
{Writable} = require 'stream'
debug = require('debug')('nanocyte-engine-router')

class Router extends Writable
  constructor: (@flowId, @instanceId, dependencies={})->
    super objectMode: true
    {NodeAssembler, @datastore} = dependencies
    @datastore ?= new (require './datastore')
    NodeAssembler ?= require './node-assembler'

    @nodeAssembler = new NodeAssembler()

  initialize: (callback=->) =>
    @nodes = @nodeAssembler.assembleNodes()

    @datastore.hget @flowId, "#{@instanceId}/router/config", (error, @config) =>
      return callback(error) if error?

      unless @config?
        errorMsg = 'router.coffee: config was not defined'
        console.error errorMsg
        return callback new Error errorMsg

      callback()

  onEnvelope: (envelope, callback) =>
    debug "onEnvelope", envelope
    toNodeIds = @getToNodeIds envelope.metadata.fromNodeId

    @sendEnvelopes toNodeIds, envelope, (error, nodes) =>
      @listenForResponses nodes
      callback()

  getToNodeIds: (fromNodeId) =>
    senderNodeConfig = @config[fromNodeId]
    unless senderNodeConfig?
      console.error 'router.coffee: senderNodeConfig was not defined'
      return []

    return senderNodeConfig.linkedTo || []

  sendEnvelopes: (toNodeIds, envelope) =>
    debug "sendEnvelopes", toNodeIds, envelope
    _.each toNodeIds, (toNodeId) => @sendEnvelope toNodeId, envelope

  sendEnvelope: (toNodeId, envelope) =>
    toNodeConfig = @config[toNodeId]
    return console.error 'router.coffee: toNodeConfig was not defined' unless toNodeConfig?

    toNode = @nodes[toNodeConfig.type]
    return console.error "router.coffee: No registered type for '#{toNodeConfig.type}'" unless toNode?

    debug "sendEnvelope", toNodeConfig, toNode

    return toNode.onEnvelope envelope

  _write: (envelope, callback) =>
    @onEnvelope envelope, callback

module.exports = Router
