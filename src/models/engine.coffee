EngineBatcher = require './engine-batcher'
EngineStreamer = require './engine-streamer'
MessageProcessQueue = require './message-process-queue'
EngineInputNode = require './engine-input-node'
debug = require('debug')('nanocyte-engine-simple:engine')

class Engine
  run: (envelope, callback) =>
    debug 'Engine.run', envelope

    node = new EngineInputNode
    EngineStreamer.add node.stream

    MessageProcessQueue.push node: node, envelope: envelope
    #
    # EngineStreamer.stream.on 'finish', =>
    #   @finish callback
    #
    # EngineStreamer.stream.on 'error', (error) =>
    #   @panic error, callback

    return EngineStreamer.stream

  panic: (error, callback) =>
    @finish =>
      callback error

  finish: (callback) =>
    EngineBatcher.flush @flowId, (flushError) =>
      console.error flushError if flushError?

    callback()

module.exports = Engine
