debug = require('debug')('nanocyte-engine-simple:engine')

EngineBatcher = require './engine-batcher'
MessageProcessQueue = require './message-process-queue'
MessageCounter = require './message-counter'
ErrorHandler = require './error-handler'
FlowTime = require './src/models/flow-time'

class Engine
  run: (envelope, callback) =>
    debug 'Engine.run', envelope
    @flowId = envelope.metadata.flowId
    @flowTime = new FlowTime {@flowId}
    @timedOutIntervalId = setInterval @timedOutInterval, 1000, callback

    ErrorHandler.onError (error, errorToSend) =>
      @finish errorToSend, callback

    MessageProcessQueue.push nodeType: 'engine-input', envelope: envelope
    MessageCounter.onDone => @finish null, callback

  finish: (errorToSend, callback) =>
    return if @alreadyFinished
    @alreadyFinished = true
    clearTimeout @timedOutIntervalId
    EngineBatcher.flush @flowId, (flushError) =>
      console.error flushError if flushError?
      @flowTime.add()
      callback errorToSend

  timedOutInterval: (callback) =>
    @flowTime.addTimedOut (error, timedOut) =>
      return unless timedOut
      errorString = "flow #{@flowId} violated max flow-time of #{@flowTime.maxTime}ms"
      console.error errorString
      @finish new Error(errorString), callback

module.exports = Engine
