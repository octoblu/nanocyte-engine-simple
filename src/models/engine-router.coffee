{Transform} = require 'stream'
_ = require 'lodash'
async = require 'async'
debug = require('debug')('nanocyte-engine-simple:engine-router')
mergeStream = require 'merge-stream'

class EngineRouter extends Transform
  constructor: (@metadata, dependencies={})->
    super objectMode: true
    {@messageProcessQueue} = dependencies

  _transform: ({config, data, message}, enc, next) =>
    config = @_setupEngineNodeRoutes config
    fromNodeConfig = config[@metadata.fromNodeId]

    toNodeIds = fromNodeConfig?.linkedTo || []
    toNodeIds = ['engine-debug'] if @metadata.msgType == 'error' and @metadata.fromNodeId != 'engine-debug'

    fromNodeName = fromNodeConfig?.type
    toNodeNames = _.map toNodeIds, (toNodeId) =>
      toNodeConfig = config[toNodeId]
      "#{toNodeConfig?.type}(#{toNodeId})"

    debug "  from: #{fromNodeName}(#{@metadata.fromNodeId})"
    debug "  to: #{toNodeNames}(#{toNodeIds})"
    @_sendMessages toNodeIds, message, config unless toNodeIds.length == 0

    @push null
    next() if next?

  _sendMessages: (toNodeIds, message, config) =>
    toNodeIds = _.sortBy toNodeIds, (toNodeId) =>
      return 0 if _.startsWith toNodeId, 'engine-'
      return 1

    _.each toNodeIds, (toNodeId, done) =>
      @_sendMessage toNodeId, message, config

  _sendMessage: (toNodeId, message, config) =>
    toNodeConfig = config[toNodeId]
    return console.error "toNodeConfig was not defined for node: #{toNodeId}" unless toNodeConfig?

    transactionGroupId = toNodeConfig.transactionGroupId
    if toNodeId == 'engine-data'
      fromNodeConfig = config[@metadata.fromNodeId]
      transactionGroupId = fromNodeConfig.transactionGroupId

    toNodeType = toNodeConfig.type

    newMetadata =
      toNodeId: toNodeId
      fromNodeId: @metadata.fromNodeId
      transactionGroupId: transactionGroupId

    envelope =
      metadata: _.extend {}, @metadata, newMetadata
      message: message

    @messageProcessQueue.push nodeType: toNodeType, envelope: envelope

  _setupEngineNodeRoutes: (config) =>
    nodesToWireToOutput = _.filter config, (node) =>
      return node.type == 'engine-debug' || node.type == 'engine-pulse'

    _.each nodesToWireToOutput, (nodeToWireToOutput) =>
      nodeToWireToOutput.linkedTo.push 'engine-batch'

    config['engine-batch'] = type: 'engine-batch'
    return config

module.exports = EngineRouter
