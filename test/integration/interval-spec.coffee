_ = require 'lodash'
async = require 'async'
debug = require('debug')('interval')
fs = require 'fs'
EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

MAX_TIMES = 100
TIMEOUT = 300000

describe 'Interval', ->
  @timeout TIMEOUT

  describe 'when instantiated with a flow', =>

    before =>
      debug 'settup flow and nodes'
      @flow = require './flows/interval.json'
      @nodes = _.map @flow.nodes, (val)=>
        return _.pick val, ['id','name','uuid']

      @intervalId = _.filter(@nodes,{name:"Interval"})?[0].id
      debug 'have intervalId', @intervalId

      @_findId = (name) =>
        _.filter(@nodes,{name})?[0].id

      @_sendInterval = (isFinished,next,sut=@sut) =>
        intervalStream = sut.messageEngine @intervalId, timestamp: ++@intervalTimes, undefined, (error, messages) =>
          throw error if error?
          # debug 'messages:', messages
          debugId = @_findId 'Debug'
          filter = message:{topic:'debug',payload:{node:debugId}}
          debugs = _.filter messages, filter
          msgs = _.map debugs, (debug) =>
            debug.message.payload.msg.payload.timestamp
          @intervalMessages = @intervalMessages.concat msgs
          return if isFinished? and isFinished()
          next(isFinished,next) if next? and @intervalTimes < MAX_TIMES

    beforeEach =>
      @sut = new EngineInAVat
        flowName: 'interval'
        # instanceId: 'interval-instance'
        flowData: @flow
        flowTime:
          maxTime: MAX_TIMES*TIMEOUT
      @intervalMessages = []
      @intervalTimes = 0
      @startTime = Date.now()
      @expected = Array(MAX_TIMES)
      _.each @expected, (v,n) => @expected[n] = n+1

    describe "and messaged sequentially #{MAX_TIMES} times", =>
      beforeEach (done) =>
        isFinishedSync = =>
          return done() or true if @intervalTimes == MAX_TIMES

        debug "trigger initializing sut #{@times}"
        @sut.initialize =>
          debug 'sut initialized'
          @_sendInterval isFinishedSync, @_sendInterval

      it "Should have the right messages", =>
        expect(@intervalMessages).to.deep.equals @expected

    describe "and messaged async #{MAX_TIMES} times", =>
      beforeEach (done) =>
        debug "trigger initializing sut #{@times}"
        @sut.initialize =>
          debug 'sut initialized'
          async.times MAX_TIMES, (n, next) =>
            debug "sending message ##{n}"
            @_sendInterval next
          , done

      it "Should have the right messages", =>
        expect(@intervalMessages.sort (a,b)=>a-b).to.deep.equals @expected
