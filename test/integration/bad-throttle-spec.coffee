_ = require 'lodash'
async = require 'async'
debug = require('debug')('bad-throttle')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
MAX_TIMES = 2
describe 'BadThrottle', ->
  @timeout 30000
  describe 'when instantiated with a flow', =>

    before =>
      debug 'settup flow and nodes'
      @flow = require './flows/bad-throttle.json'
      @nodes = _.map @flow.nodes, (val)=>
        return _.pick val, ['id','name','uuid']
      @throttleId = _.filter(@nodes,{name:"Throttle"})?[0].id
      debug 'have throttleId', @throttleId
      @triggerId = _.filter(@nodes,{name:"Trigger"})?[0].id
      debug 'have triggerId', @triggerId

      @_translate = (id) =>
        filter = _.filter(@nodes,{id:id})?[0]
        return filter?.name or id

      @_debugMsg = (msg) =>
        fromNodeId = @_translate(msg.metadata.fromNodeId)
        toNodeId = @_translate(msg.metadata.toNodeId)
        debugFromNodeId = @_translate(msg.metadata.debugInfo?.fromNode?.config.id)
        debugToNodeId = @_translate(msg.metadata.debugInfo?.toNode?.config.id)
        debug "  - debugInfo #{debugFromNodeId}(#{fromNodeId})=>#{debugToNodeId}(#{toNodeId})"
        # debug 'throttle response:', fromNodeId, '=>', toNodeId, ':', JSON.stringify(msg.message, null, 2)

      @_pushThrottleDebug = (msg) =>
        @_debugMsg msg
        return unless msg?.message?.topic == 'debug'
        return unless msg?.metadata?.fromNodeId
        node = @_translate(msg.message?.payload?.node)
        debug 'checking output to ', node, "(#{msg.message?.payload?.node})"
        return unless node == 'Debug-Throttle'
        @throttleMessages.push msg.message.payload.msg

      @_sendThrottle = (isFinished,next,sut=@sut) =>
        @throttleTimes++
        throttleStream = sut.messageEngine @throttleId, timestamp: Date.now()
        throttleStream.on 'data', @_pushThrottleDebug
        throttleStream.on 'finish', =>
          debug 'throttleStream finished'
          return if isFinished? and isFinished()
          next(isFinished,next) if next?

    beforeEach =>
      console.log 'initializing sut'
      @sut = new EngineInAVat flowName: 'bad-throttle', flowData: @flow, instanceId: 'bad-throttle-instance'
      @throttleMessages = []
      @times = 0

    describe "and messaged sequentially #{MAX_TIMES} times", =>
      beforeEach (done) =>
        isFinished = =>
          @times++
          process.stdout.write "#{@throttleMessages.length} "
          return done(new Error 'missed a message') if @times != @throttleMessages.length
          return done() if @times == MAX_TIMES

        debug "trigger initializing sut #{@times}"
        @sut.initialize =>
          debug 'sut initialized'
          triggerStream = @sut.triggerByName name: 'Trigger'
          triggerStream.on 'data', @_pushThrottleDebug
          triggerStream.on 'finish', =>
            debug 'responseStream finished'
            @_sendThrottle(isFinished,@_sendThrottle)

      it "Should have the right number length of debugs", =>
        console.log '!'
        expect(@throttleMessages.length).to.equals MAX_TIMES

    describe.only "and messaged async #{MAX_TIMES} times", =>
      beforeEach (done) =>
        debug "trigger initializing sut #{@times}"
        triggerSuts = []

        async.times MAX_TIMES, (n, next) =>
          triggerSuts[n] = new EngineInAVat flowName: 'bad-throttle', flowData: @flow, instanceId: 'bad-throttle-instance'
          triggerSuts[n].initialize next
          debug 'done init trigger sut',n

        @sut.initialize =>
          debug 'sut initialized'
          triggerStream = @sut.triggerByName name: 'Trigger'
          triggerStream.on 'data', @_pushThrottleDebug
          triggerStream.on 'finish', =>
            debug 'responseStream finished'

            async.times MAX_TIMES, (n, next) =>
              debug "sending Throttle message ##{n}"
              isFinished = =>
                @times++
                # process.stdout.write "#{@throttleMessages.length} "
                console.log n, @times, @throttleMessages.length
                # return done(new Error 'missed a message') if @times != @throttleMessages.length
                return done() if @times == MAX_TIMES
                next()

              @_sendThrottle(isFinished, null, triggerSuts[n])

      it "Should have the right number length of debugs", =>
        console.log '!'
        expect(@throttleMessages.length).to.equals MAX_TIMES
