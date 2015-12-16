_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:engine')

class Engine

  constructor: (@options={}, @dependencies={}) ->
    {@FlowTime} = @dependencies
    @FlowTime ?= require './flow-time'
    Engine.populateDependencies @options, @dependencies
    {@errorHandler, @messageProcessQueue, @messageCounter, @engineBatcher} = @dependencies

  @populateDependencies: (options={},depends={}) ->
    depends.instanceCount        = ++Engine.instanceCount
    depends.messageCounter      ?= new (require './message-counter') options, depends
    depends.lockManager         ?= new (require './lock-manager') options, depends
    depends.errorHandler        ?= new (require './error-handler') options, depends
    depends.engineBatcher       ?= new (require './engine-batcher') options, depends
    depends.messageRouteQueue   ?= new (require './message-route-queue') options, depends
    depends.messageProcessQueue ?= new (require './message-process-queue') options, depends
    depends.errorHandler.updateDependencies depends
    depends

  @instanceCount: 0

  run: (envelope, @callback) =>
    debug 'Engine.run', envelope
    @callback new Error 'aborting stale engine instance' if @flowId?
    @flowId = envelope.metadata.flowId
    @callback new Error 'flowId is not defined, aborting' unless @flowId?
    @flowTime = new @FlowTime _.extend({},@options,{@flowId}), @dependencies
    @checkTimedOutIntervalId = setInterval @_checkTimedOut, 1000
    @errorHandler.onError (error, errorToSend) =>
      @_finish errorToSend
    @messageProcessQueue.push nodeType: 'engine-input', envelope: envelope
    @messageCounter.onDone => @_finish null

  _finish: (errorToSend) =>
    return if @finished
    @finished = true
    clearTimeout @checkTimedOutIntervalId
    @engineBatcher.flushAll (flushError) =>
      console.error flushError if flushError?
      @flowTime.add()
      @callback errorToSend

  _checkTimedOut: =>
    @flowTime.addTimedOut (error, timedOut) =>
      return unless timedOut
      errorString = "flow #{@flowId} violated max flow-time of #{@flowTime.maxTime}ms"
      console.error errorString
      @_finish new Error(errorString)

module.exports = Engine
