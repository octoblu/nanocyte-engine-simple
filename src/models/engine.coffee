debug = require('debug')('nanocyte-engine-simple:engine')

EngineBatcher = require './engine-batcher'
MessageProcessQueue = require './message-process-queue'
EngineInputNode = require './engine-input-node'
MessageCounter = require './message-counter'
ErrorHandler = require './error-handler'


class Engine
  run: (envelope, callback) =>
    debug 'Engine.run', envelope

    ErrorHandler.onError (error, errorToSend) =>
      @finish errorToSend, callback

    node = new EngineInputNode
    MessageProcessQueue.push node: node, envelope: envelope
    MessageCounter.onDone => @finish null, callback

  finish: (errorToSend, callback) =>
    EngineBatcher.flush @flowId, (flushError) =>
      console.error flushError if flushError?
    callback()

module.exports = Engine
