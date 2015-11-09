_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:flow-time')
class FlowTime
  constructor: (options={}, dependencies={})->
    {@flowId, @maxTime, @expires} = options
    @maxTime ?= 30000
    @expires ?= 60*60
    {@datastore} = dependencies
    @datastore ?= new (require './datastore')

    @startTime = Date.now()
    @lastTime = @startTime
    @minuteKey = @getMinute(@startTime)

  getMinute: (time)=>
    @startMinute = Math.floor(time / (1000*60))
    return "stats-#{@flowId}-minute-#{@startMinute}"

  get: (callback)=>
    @datastore.get @minuteKey, callback

  getTimedOut: (callback)=>
    @datastore.get @minuteKey, (error, time) =>
      return callback error if error?
      callback null, @timedOut time

  timedOut: (time)=>
    return time >= @maxTime

  add: (callback=->) =>
    now = Date.now()
    elapsedTime = now - @lastTime
    @lastTime = now
    @datastore.getAndIncrementCount @minuteKey, elapsedTime, @expires, callback

  addTimedOut: (callback) =>
    @add (error, time) =>
      return callback error if error?
      return callback null, @timedOut time

module.exports = FlowTime
