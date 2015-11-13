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
    node.stream.on 'finish', callback
    node.stream.on 'readable', =>
      stream = new PassThrough objectMode: true
      EngineStreamer.add stream

      receivedEnvelope = node.stream.read()
      debug 'processed envelope:', receivedEnvelope
      return stream.end() unless receivedEnvelope?

      {metadata, message} = receivedEnvelope
      {toNodeId} = metadata

      newMetadata = _.clone metadata
      newMetadata.fromNodeId = toNodeId
      newMetadata.toNodeId = 'router'

      newEnvelope =
        metadata: newMetadata
        message: message

      debug 'enqueueueueing envelope', newEnvelope
      MessageRouteQueue.push envelope: newEnvelope, stream: stream

    debug 'sending message:', envelope
    node.message envelope    

module.exports = new MessageProcessQueue
