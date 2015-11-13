_ = require 'lodash'
async = require 'async'
MessageRouteQueue = require './message-route-queue'
debug = require('debug')('nanocyte-engine-simple:message-process-queue')
{PassThrough} = require 'stream'
EngineStreamer = require './engine-streamer'

class MessageProcessQueue
  constructor: ->
    @queue = async.queue @_processMessage, 1

  push: (envelope) =>
    @queue.push envelope

  _processMessage: ({node, envelope}, callback) =>
    node.stream.on 'finish', =>
      EngineStreamer.subtract()
      callback()

    node.stream.on 'readable', =>
      EngineStreamer.add()
      receivedEnvelope = node.stream.read()
      debug 'processed envelope:', receivedEnvelope

      unless receivedEnvelope?
        EngineStreamer.subtract()
        return

      {metadata, message} = receivedEnvelope
      {toNodeId} = metadata

      newMetadata = _.clone metadata
      newMetadata.toNodeId = 'router'

      newEnvelope =
        metadata: newMetadata
        message: message

      debug 'enqueueueueing envelope', newEnvelope
      MessageRouteQueue.push envelope: newEnvelope

    debug 'sending message:', envelope
    node.sendEnvelope envelope

module.exports = new MessageProcessQueue
