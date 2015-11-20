debug = require('debug')('nanocyte-engine-simple:engine')

EngineBatcher = require './engine-batcher'
MessageProcessQueue = require './message-process-queue'
MessageCounter = require './message-counter'
ErrorHandler = require './error-handler'


class Engine
  run: (envelope, callback) =>
    debug 'Engine.run', envelope
    @flowId = envelope.metadata.flowId

    ErrorHandler.onError (error, errorToSend) =>
      @finish errorToSend, callback

    MessageProcessQueue.push nodeType: 'engine-input', envelope: envelope
    MessageCounter.onDone => @finish null, callback

  finish: (errorToSend, callback) =>
    EngineBatcher.flush @flowId, (flushError) =>
      console.error flushError if flushError?
      callback errorToSend

module.exports = Engine
