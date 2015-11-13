EngineBatcher = require './engine-batcher'
EngineStreamer = require './engine-streamer'
MessageProcessQueue = require './message-process-queue'
EngineInputNode = require './engine-input-node'
debug = require('debug')('nanocyte-engine-simple:engine')

class Engine
  run: (envelope, callback) =>
    debug 'Engine.run', envelope

    node = new EngineInputNode
    MessageProcessQueue.push node: node, envelope: envelope

    EngineStreamer.onDone => @finish callback

    return EngineStreamer.stream

  # panic: (error, callback) =>
  #   @finish =>
  #     callback error

  finish: (callback) =>
    EngineBatcher.flush @flowId, (flushError) =>
      console.error flushError if flushError?

    callback()

module.exports = Engine
