_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:flow-time')

class FlowTime
  constructor: (options={}, dependencies={})->
    {@flowId, flowTime} = options
    flowTime ?= {}
    {@maxTime, @expires} = flowTime
    @maxTime ?= 1000*60*2
    @expires ?= 60*60
    {@datastore, @Date} = dependencies
    @datastore ?= new (require './datastore')
    @Date ?= Date
    @lastTime = @Date.now()

  fetchFlowOptions: (callback) =>
    @datastore.hget "flowtime-options-#{@flowId}", "maxTime", (error, maxTime) =>
      return callback error if error?
      {@maxTime, @expires} = options


  getMinute: (time)=>
    time ?= @Date.now()
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
    now = @Date.now()
    elapsedTime = now - @lastTime
    @lastTime = now
    @datastore.getAndIncrementCount @getMinute(), elapsedTime, @expires, (error, time) =>
      @totalTime = time
      callback(error,time)

  addTimedOut: (callback) =>
    @add (error, time) =>
      return callback error, error? or @timedOut time

module.exports = FlowTime
