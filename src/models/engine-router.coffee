{Transform} = require 'stream'
_ = require 'lodash'
async = require 'async'
debug = require('debug')('nanocyte-engine-simple:engine-router')
mergeStream = require 'merge-stream'

MessageProcessQueue = require './message-process-queue'
MessageCounter = require './message-counter'

class EngineRouter extends Transform
  constructor: (@metadata, dependencies={})->
    super objectMode: true


  _transform: ({config, data, message}, enc, next) =>
    config = @_setupEngineNodeRoutes config
    fromNodeConfig = config[@metadata.fromNodeId]

    toNodeIds = fromNodeConfig?.linkedTo || []
    toNodeIds = ['engine-debug'] if @metadata.msgType == 'error' and @metadata.fromNodeId != 'engine-debug'

    fromNodeName = fromNodeConfig?.type
    toNodeNames = _.map toNodeIds, (toNodeId) =>
      toNodeConfig = config[toNodeId]
      "#{toNodeConfig?.type}(#{toNodeId})"

    # unless _.isEmpty toNodeNames
    # debug "Incoming message #{JSON.stringify message}"
    debug "  from: #{fromNodeName}(#{@metadata.fromNodeId})"
    debug "  to: #{toNodeNames}(#{toNodeIds})"

    return @push null if toNodeIds.length == 0

    @_sendMessages toNodeIds, message, config

  _sendMessages: (toNodeIds, message, config) =>
    toNodeIds = _.sortBy toNodeIds, (toNodeId) =>
        return 0 if _.startsWith toNodeId, 'engine-'
        return 1

    _.each toNodeIds, (toNodeId, done) =>
      MessageCounter.add()
      @_sendMessage toNodeId, message, config

    @push null

  _sendMessage: (toNodeId, message, config) =>
    toNodeConfig = config[toNodeId]
    return console.error "toNodeConfig was not defined for node: #{toNodeId}" unless toNodeConfig?

    # ToNodeClass = @nodes[toNodeConfig.type]
    # return console.error "No registered type for '#{toNodeConfig.type}' for node #{toNodeId}" unless ToNodeClass?

    transactionGroupId = toNodeConfig.transactionGroupId
    if toNodeId == 'engine-data'
      fromNodeConfig = config[@metadata.fromNodeId]
      transactionGroupId = fromNodeConfig.transactionGroupId

    # toNode = new ToNodeClass()
    toNode = toNodeConfig.type

    newMetadata =
      toNodeId: toNodeId
      fromNodeId: @metadata.fromNodeId
      transactionGroupId: transactionGroupId

    envelope =
      metadata: _.extend {}, @metadata, newMetadata
      message: message

    MessageProcessQueue.push node: toNode, envelope: envelope
    MessageCounter.subtract()

  _setupEngineNodeRoutes: (config) =>
    nodesToWireToOutput = _.filter config, (node) =>
      return node.type == 'engine-debug' || node.type == 'engine-pulse'

    _.each nodesToWireToOutput, (nodeToWireToOutput) =>
      nodeToWireToOutput.linkedTo.push 'engine-batch'

    config['engine-batch'] = type: 'engine-batch'
    return config

module.exports = EngineRouter
