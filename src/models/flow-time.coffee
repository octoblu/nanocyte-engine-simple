_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:flow-time')

class FlowTime
  constructor: (options={}, dependencies={})->
    {@flowId, flowTime} = options
    flowTime ?= {}
    {@maxTime, @expires} = flowTime
    @maxTime ?= Number.parseInt(process.env.FLOW_TIME_MAX) or 1000*60*10
    @expires ?= Number.parseInt(process.env.FLOW_TIME_EXPIRES) or 60*60
    {@datastore, @Date} = dependencies
    @datastore ?= new (require './datastore') options, dependencies
    @Date ?= Date
    @lastTime = @Date.now()

  fetchFlowOptions: (callback) =>
    fields = [
      "maxTime"
      "expires"
    ]
    @datastore.hmget "flowtime-options-#{@flowId}", fields, (error, [maxTime, expires]) =>
      return callback error if error?
      @maxTime = maxTime if maxTime?
      @expires = expires if expires?
      callback()

  blackhole: (callback=->) =>
    @datastore.set "request-queue-name:#{@flowId}", "request:blackhole", callback

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
