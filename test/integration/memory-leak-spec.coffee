_ = require 'lodash'
async = require 'async'
debug = require('debug')('memory-leak')
fs = require 'fs'
EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

MAX_TIMES = 2000
describe 'MemoryLeak', ->
  @timeout 30000000
  describe 'when instantiated with a flow', ->

    before ->
      debug 'settup flow and nodes'
      @flow = require './flows/memory-leak.json'
      @bigBook = fs.readFileSync './test/integration/data/big-book.txt', 'utf-8'
      # @bigBookArray = ["a","b"]
      @bigBookArray = Array(2).fill @bigBook, 0, 2
      @nodes = _.map @flow.nodes, (val)=>
        return _.pick val, ['id','name','uuid']

      @_translate = (id) =>
        filter = _.filter(@nodes,{id:id})?[0]
        return filter?.name or id

      @_debugMsg = (msg) =>
        fromNodeId = @_translate(msg.metadata.fromNodeId)
        toNodeId = @_translate(msg.metadata.toNodeId)
        debugFromNodeId = @_translate(msg.metadata.debugInfo?.fromNode?.config.id)
        debugToNodeId = @_translate(msg.metadata.debugInfo?.toNode?.config.id)
        debug "  - debugInfo #{debugFromNodeId}(#{fromNodeId})=>#{debugToNodeId}(#{toNodeId})"
        # debug 'trigger response:', fromNodeId, '=>', toNodeId, ':', JSON.stringify(msg.message, null, 2)

      @_pushTriggerDebug = (msg) =>
        @_debugMsg msg
        return unless msg?.message?.topic == 'debug'
        return unless msg?.metadata?.fromNodeId
        node = @_translate(msg.message?.payload?.node)
        debug 'checking output to ', node, "(#{msg.message?.payload?.node})"
        return unless node == 'Debug'
        @triggerMessages.push msg.message.payload.msg

      @_sendTrigger = (isFinished,next,sut=@sut) =>
        @triggerTimes++
        triggerStream = sut.triggerByName name: 'Trigger', message: {timestamp: Date.now(), book: @bigBookArray}
        triggerStream.on 'data', @_pushTriggerDebug
        triggerStream.on 'finish', =>
          debug 'triggerStream finished'
          return if isFinished? and isFinished()
          next(isFinished,next) if next?

    beforeEach ->
      console.log 'initializing sut'
      @sut = new EngineInAVat flowName: 'memory-leak', flowData: @flow, instanceId: 'memory-leak-instance'
      @triggerMessages = []
      @times = 0
      @startTime = Date.now()
    describe.only "and messaged sequentially #{MAX_TIMES} times", ->
      beforeEach (done) ->
        isFinished = =>
          console.log "Time: #{Date.now() - @startTime}"
          @startTime = Date.now()
          console.log process.memoryUsage()
          @times++
          process.stdout.write "#{@triggerMessages.length} "
          return done(new Error 'missed a message') if @times != @triggerMessages.length
          return done() if @times == MAX_TIMES

        debug "trigger initializing sut #{@times}"
        @sut.initialize =>
          debug 'sut initialized'
          triggerStream = @sut.triggerByName name: 'Trigger', message: book: @bigBookArray
          triggerStream.on 'finish', =>
            debug 'responseStream finished'
            @_sendTrigger(isFinished,@_sendTrigger)

      it "Should have the right number length of debugs", ->
        console.log '!'
        expect(@triggerMessages.length).to.equals MAX_TIMES
