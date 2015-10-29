{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-router')
mergeStream = require 'merge-stream'

class EngineRouter extends Transform
  constructor: (options, dependencies={})->
    super objectMode: true
    {@fromNodeId} = options
    {NodeAssembler, @lockManager} = dependencies

    @nodes = new @nodeAssembler.assembleNodes()

  _transform: ({config, data, message}, enc, next) =>
    toNodeIds = config[@fromNodeId]?.linkedTo || []

    if toNodeIds.length == 0
      @push null
      return next()

    messageStreams = @_sendMessages toNodeIds, config
    messageStreams.on 'readable', => @push messageStreams.read()

  _sendMessages: (toNodeIds, config) =>
    messageStreams = mergeStream()

    _.each toNodeIds, (toNodeId) =>
      messageStream = @_sendMessage(toNodeId, message, config)
      messageStreams.add messageStream if messageStream?

    messageStreams

  _sendMessage: (toNodeId, message, config) =>
    toNodeConfig = config[toNodeId]

    return _logError "toNodeConfig was not defined for node: #{toNodeId}" unless toNodeConfig?
    ToNodeClass = nodes[toNodeConfig.type]

    return _logError "No registered type for '#{toNodeConfig.type}' for node #{toNodeId}" unless ToNodeClass?

    envelope =
      metadata: _.extend {}, metadata,
        toNodeId: toNodeId
        fromNodeId: @fromNodeId
        transactionId: 0
      message: message

    new ToNodeClass().message envelope


module.exports = EngineRouter
