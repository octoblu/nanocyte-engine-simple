_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:flow-time')
class FlowTime
  constructor: (options={}, dependencies={})->
    {@flowId, @maxTime, @expires} = options
    @maxTime ?= 1000*60*2
    @expires ?= 60*60
    {@datastore} = dependencies
    @datastore ?= new (require './datastore')
    @lastTime = Date.now()

  getMinute: (time)=>
    time ?= Date.now()
    @startMinute = Math.floor(time / (1000*60))
    return "stats-#{@flowId}-minute-#{@startMinute}"

  get: (callback)=>
    @datastore.get @getMinute(), (error, time) =>
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
    @datastore.getAndIncrementCount @getMinute(), elapsedTime, @expires, (error, time) =>
      @totalTime = time
      callback(error,time)

  addTimedOut: (callback) =>
    @add (error, time) =>
      return callback error, error? or @timedOut time

module.exports = FlowTime
