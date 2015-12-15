_ = require 'lodash'
async = require 'async'
debug = require('debug')('bad-throttle')
fs = require 'fs'
EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

MAX_TIMES = 100
TIMEOUT = 300000
describe 'BadThrottle', ->
  @timeout TIMEOUT
  describe 'when instantiated with a flow', =>

    before =>
      debug 'settup flow and nodes'
      @flow = require './flows/bad-throttle.json'
      @nodes = _.map @flow.nodes, (val)=>
        return _.pick val, ['id','name','uuid']

      @throttleId = _.filter(@nodes,{name:"Throttle"})?[0].id
      debug 'have throttleId', @throttleId

      @_findId = (name) =>
        _.filter(@nodes,{name})?[0].id

      @_sendThrottle = (isFinished,next,sut=@sut) =>
        @throttleTimes++
        throttleStream = sut.messageEngine @throttleId, timestamp: Date.now(), undefined, (error, messages) =>
          throw error if error?
          debugId = @_findId 'Debug-Throttle'
          filter = message:{topic:'debug',payload:{node:debugId}}
          debugs = _.filter messages, filter
          msgs = _.map debugs, (debug) => debug.message.payload.msg
          debug 'msgs:', msgs
          @throttleMessages = @throttleMessages.concat msgs
          return if isFinished? and isFinished()
          next(isFinished,next) if next? and @throttleTimes < MAX_TIMES

    beforeEach =>
      @sut = new EngineInAVat
        flowName: 'bad-throttle'
        instanceId: 'bad-throttle-instance'
        flowData: @flow
        flowTime:
          maxTime: MAX_TIMES*TIMEOUT
      @throttleMessages = []
      @throttleTimes = 0
      @startTime = Date.now()

    describe "and messaged sequentially #{MAX_TIMES} times", =>
      beforeEach (done) =>
        isFinishedSync = =>
          return done(new Error 'missed a sync message') if @throttleTimes != @throttleMessages.length
          return done() if @throttleTimes == MAX_TIMES

        debug "trigger initializing sut #{@times}"
        @sut.initialize =>
          debug 'sut initialized'
          @sut.triggerByName name: 'Trigger', =>
            @_sendThrottle isFinishedSync, @_sendThrottle

      it "Should have the messages in order", =>
        expect(@throttleMessages.length).to.equals MAX_TIMES
        expect(@throttleMessages.join('')).to.equals 'ab'.repeat(50)

    describe "and messaged async #{MAX_TIMES} times", =>
      beforeEach (done) =>
        isFinishedASync = =>
          return done() if @throttleMessages.length == MAX_TIMES
          return done(new Error 'missed an async message')

        debug "trigger initializing sut #{@times}"
        @sut.initialize =>
          debug 'sut initialized'
          @sut.triggerByName name: 'Trigger', =>
            async.times MAX_TIMES, (n, next) =>
              debug "sending Throttle message ##{n}"
              @_sendThrottle next
            , isFinishedASync

      it "Should have the right number length of debugs", =>
        expect(@throttleMessages.length).to.equals MAX_TIMES
        console.log 'ab'.repeat(50)
        console.log @throttleMessages.join('')
