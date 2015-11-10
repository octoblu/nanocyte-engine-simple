_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:flow-time')
class FlowTime
  constructor: (options={}, dependencies={})->
    {@flowId, @maxTime, @expires} = options
    @maxTime ?= 3000
    @expires ?= 60 #60*60
    {@datastore} = dependencies
    @datastore ?= new (require './datastore')

    @startTime = Date.now()
    @lastTime = @startTime
    @minuteKey = @getMinute(@startTime)

  getMinute: (time)=>
    @startMinute = Math.floor(time / (1000*60))
    return "stats-#{@flowId}-minute-#{@startMinute}"

  get: (callback)=>
    @datastore.get @minuteKey, (error, time) =>
      @totalTime = time
      callback(error,time)

  getTimedOut: (callback)=>
    @get (error, time) =>
      callback error, error? or @timedOut time

  timedOut: (time)=>
    return time >= @maxTime

  add: (callback=->) =>
    now = Date.now()
    elapsedTime = now - @lastTime
    @lastTime = now
    @datastore.getAndIncrementCount @minuteKey, elapsedTime, @expires, (error, time) =>
      @totalTime = time
      callback(error,time)

  addTimedOut: (callback) =>
    @add (error, time) =>
      return callback error, error? or @timedOut time

module.exports = FlowTime
