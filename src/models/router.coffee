{Writable} = require 'stream'
debug = require('debug')('nanocyte-engine-router')

class Router extends Writable
  constructor: (@flowId, @instanceId, dependencies={})->
    super objectMode: true
    {@datastore} = dependencies
    @datastore ?= new (require './datastore')

  initialize: (callback=->) =>
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

  getToNodeIds: (fromNodeId, callback) =>
    senderNodeConfig = @config[fromNodeId]
    console.error 'router.coffee: senderNodeConfig was not defined' unless senderNodeConfig?
    return renderNodeConfig?.linkedTo || []

  sendEnvelopes: (toNodeIds, envelope) =>
    debug "sendEnvelopes", toNodeIds, envelope

  _write: (envelope, callback) =>
    @onEnvelope envelope, callback

module.exports = Router
