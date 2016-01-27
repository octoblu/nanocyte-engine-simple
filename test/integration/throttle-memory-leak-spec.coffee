_ = require 'lodash'
async = require 'async'
debug = require('debug')('memory-leak')
fs = require 'fs'
EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
# heapdump = require 'heapdump'

MAX_TIMES = 100
ASYNC_THROTTLE = 5
MAX_RSS = 175*1000*1000

xdescribe 'Throttle MemoryLeak', ->
  @timeout 12000000
  describe 'when instantiated with a flow', =>

    before =>
      debug 'settup flow and nodes'
      @flow = require './flows/throttle-memory-leak.json'

      @triggerMessages = []
      @times = 0
      @bigBook = '01'.repeat 500*1000
      @bigBookArray = Array(2).fill @bigBook, 0, 2

      @nodes = _.map @flow.nodes, (val)=>
        return _.pick val, ['id','name','uuid']

      @throttleTimes = 0
      @throttleId = _.filter(@nodes,{name:"Throttle"})?[0].id

      @_findId = (name) =>
        _.filter(@nodes,{name})?[0].id

      @_sendTrigger = (isFinished,next) =>
        triggerData = name: 'Trigger', message: {timestamp: Date.now(), book: @bigBookArray}
        sut = new EngineInAVat flowName: 'memory-leak', flowData: @flow, instanceId: 'memory-leak-instance'
        sut.initialize =>
          sut.triggerByName triggerData, (error, messages) =>
            throw error if error?
            async.times ASYNC_THROTTLE, async.apply(@_sendThrottle, sut), (error) =>
              throw error if error?
              return if isFinished? && isFinished()
              next(isFinished,next) if next?
              #  && @throttleTimes < MAX_TIMES

      @_sendThrottle = (sut,i,callback) =>
        @throttleTimes++
        sut.messageEngine @throttleId, timestamp: Date.now(), undefined, callback
        # (error, messages) =>
        #   throw error if error?
        #   # debug 'messages:', messages
        #   debugId = @_findId 'Debug'
        #   filter = message:{topic:'debug',payload:{node:debugId}}
        #   debugs = _.filter messages, filter
        #   console.log 'msgs:', debugs
        #   msgs = _.map debugs, (debug) =>
        #     debug.message.payload.msg.payload.message.timestamp
        #   @triggerMessages = @triggerMessages.concat msgs
        #   callback()
          # return if isFinished? and isFinished()
          # next(isFinished,next) if next?
          # and @intervalTimes < MAX_TIMES

    describe "and messaged sequentially #{MAX_TIMES} times", =>
      before (done) =>
        isFinished = =>
          @times++
          global.gc()
          # heapdump.writeSnapshot()
          rss = process.memoryUsage().rss
          # console.log "run #{@times} rss: #{rss}"
          # return done(new Error "run #{@times} missed a message") or true if @times != @triggerMessages.length
          return done(new Error "run #{@times} failed using too much memory: #{rss}") or true if rss > MAX_RSS
          return done() or true if @times == MAX_TIMES

        debug "trigger initializing sut #{@times}"
        @_sendTrigger isFinished, @_sendTrigger

      it "Should have run without using more than #{MAX_RSS} bytes of RSS memory", =>
        expect(true).to.equals true
