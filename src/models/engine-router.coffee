{Transform} = require 'stream'
_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:engine-router')

class EngineRouter extends Transform
  constructor: (@metadata, dependencies={})->
    super objectMode: true
    {@messageProcessQueue} = dependencies

  _transform: ({config, data, message}, enc, next) =>
    config          = @_setupEngineNodeRoutes config
    fromNodeConfig  = config[@metadata.fromNodeId]
    toNodeIds       = @_getToNodeIds fromNodeConfig
    fromNodeName    = fromNodeConfig?.type

    @_sendMessages toNodeIds, message, config unless toNodeIds.length == 0

    @push null
    next() if next?

  _getToNodeIds: (fromNodeConfig) =>
    eventType = _.first(@metadata.metadata.route)?.type
    return ['engine-debug'] if @metadata.msgType == 'error' and @metadata.fromNodeId != 'engine-debug'
    debug "getToNodeIds", {fromNodeId: @metadata.fromNodeId, eventType, linkedTo: fromNodeConfig?.linkedTo, eventLinks: fromNodeConfig?.eventLinks}
    return _.compact [].concat(fromNodeConfig?.linkedTo, fromNodeConfig?.eventLinks?[eventType])

  _sendMessages: (toNodeIds, message, config) =>
    toNodeIds = _.sortBy toNodeIds, (toNodeId) =>
      return 0 if _.startsWith toNodeId, 'engine-'
      return 1

    _.each toNodeIds, (toNodeId) =>
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

    newMetadata.originalMessage = message if config[@metadata.fromNodeId]?.linkedToNext

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
    @_setupPing config

  _setupPing: (config) =>
    config['engine-ping'] =
      type: 'engine-ping'
      linkedTo: ['engine-output']

    config['engine-ping-input'] =
      linkedTo: ['engine-ping']

    return config

module.exports = EngineRouter
