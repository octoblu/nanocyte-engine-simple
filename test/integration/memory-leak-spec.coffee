_ = require 'lodash'
async = require 'async'
debug = require('debug')('memory-leak')
fs = require 'fs'
EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
heapdump = require 'heapdump'

MAX_TIMES = 1000
xdescribe 'MemoryLeak', ->
  @timeout 12000000
  describe 'when instantiated with a flow', =>

    before =>
      debug 'settup flow and nodes'
      @flow = require './flows/memory-leak.json'

      @triggerMessages = []
      @times = 0
      @bigBook = '01'.repeat 500*1000
      @bigBookArray = Array(2).fill @bigBook, 0, 2

      @nodes = _.map @flow.nodes, (val)=>
        return _.pick val, ['id','name','uuid']

      @_findId = (name) =>
        _.filter(@nodes,{name})?[0].id

      @_sendTrigger = (isFinished,next) =>
        triggerData = name: 'Trigger', message: {timestamp: Date.now(), book: @bigBookArray}
        sut = new EngineInAVat flowName: 'memory-leak', flowData: @flow, instanceId: 'memory-leak-instance'
        sut.initialize =>
          sut.triggerByName triggerData, (error, messages) =>
            throw error if error?
            debugId = @_findId 'Debug'
            filter = message:{topic:'debug',payload:{node:debugId}}
            debugs = _.filter messages, filter
            @triggerMessages.push 'debugs' if debugs?
            return if isFinished? and isFinished()
            next(isFinished,next) if next?

    describe "and messaged sequentially #{MAX_TIMES} times", =>
      before (done) =>
        isFinished = =>
          @times++
          global.gc()
          heapdump.writeSnapshot()
          rss = process.memoryUsage().rss
          debug rss
          return done(new Error "run #{@times} missed a message") or true if @times != @triggerMessages.length
          console.log 'rss:', rss
          # return done(new Error "run #{@times} failed using too much memory: #{rss}") or true if rss > 175*1000*1000
          return done() or true if @times == MAX_TIMES

        debug "trigger initializing sut #{@times}"
        @_sendTrigger(isFinished,@_sendTrigger)

      it "Should have the right number length of debugs", =>
        expect(@triggerMessages.length).to.equals MAX_TIMES
