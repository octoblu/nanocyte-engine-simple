debugStream = require('debug-stream')('nanocyte-engine-simple:engine-input-throttle')
EngineInput = require './engine-input'

ERROR_MSG = 'CPU time out'

class EngineInputThrottle extends EngineInput
  constructor: (options={}, dependencies={}) ->
    {@flowId, @throttleIntervalFrequency} = options
    @throttleIntervalFrequency ?= 1000

    {FlowTime} = dependencies
    FlowTime ?= require './flow-time'
    @flowTime = new FlowTime flowId: @flowId

    @errorMsg = "#{@flowId} #{ERROR_MSG}"
    super options, dependencies

  _transform: (msg, enc, next)=>
    return super msg, enc, next if @alreadyChecked
    @flowTime.getTimedOut (error, timedOut) =>
      @alreadyChecked = true
      if timedOut
        @flushAndEnd()
        alreadyErrored = "#{@errorMsg} on transform due to #{@flowTime.totalTime}ms of previous use"
        console.error alreadyErrored
        throw new Error(alreadyErrored)
      @intervalId = setInterval @_checkTimedOut, @throttleIntervalFrequency
      super msg, enc, next

  _checkTimedOut: =>
    @flowTime.addTimedOut (error, timedOut) =>
      if timedOut
        timeoutError = "#{@errorMsg} after #{@flowTime.totalTime}ms"
        console.error timeoutError
        throw new Error(timeoutError)

  flushAndEnd: =>
    clearInterval @intervalId
    super
    @flowTime.add()

module.exports = EngineInputThrottle
