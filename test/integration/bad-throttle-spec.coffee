_ = require 'lodash'
debug = require('debug')('bad-throttle')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
MAX_TIMES = 1000
DEBUG_TIMES= 6
describe 'BadThrottle', ->
  @timeout 300000
  describe 'when instantiated with a flow', ->

    beforeEach ->
      debug 'settup flow and nodes'
      @flow = require './flows/bad-throttle.json'
      # debug @flow.nodes

      @nodes = _.map @flow.nodes, (val)=>
        return _.pick val, ['id','name','uuid']
      # debug JSON.stringify @nodes, null, 2
      @throttleId = _.filter(@nodes,{name:"Throttle"})?[0].id
      debug 'have throttleId', @throttleId
      @triggerId = _.filter(@nodes,{name:"Trigger"})?[0].id
      debug 'have triggerId', @triggerId

      @sut = new EngineInAVat flowName: 'bad-throttle', flowData: @flow, instanceId: 'bad-throttle-instance'
      @throttleMessages = []

    beforeEach (done) ->
      debug 'setup tests'

      @times = 0
      @failure = false

      translate = (id)=>
        filter = _.filter(@nodes,{id:id})?[0]
        return filter?.name or id

      maybeFinish = =>
        @times++
        # @engineDebugs = _.filter @messages, (message) =>
        #   message.metadata.toNodeId == 'engine-debug'
        # if @engineDebugs.length != DEBUG_TIMES
        #   @failure = true
        #   return done()
        process.stdout.write "#{@throttleMessages.length} "
        # console.log 'times=',@times,' : throttleMessages.size=', @throttleMessages.length
        return done(new Error 'missed a message') if @times != @throttleMessages.length
        return done() if @times == MAX_TIMES
        # testIt()

      sendThrottle = =>
        @throttleTimes++
        throttleStream = @sut.messageEngine @throttleId, timestamp: Date.now()
        throttleStream.on 'data', (msg) =>
          msg = _.cloneDeep msg
          fromNodeId = translate(msg.metadata.fromNodeId)
          toNodeId = translate(msg.metadata.toNodeId)
          fromId = msg.message?.payload?.from
          msg.message.payload.fromName = translate fromId if fromId

          debugFromNodeId = translate(msg.metadata.debugInfo?.fromNode?.config.id)
          debugToNodeId = translate(msg.metadata.debugInfo?.toNode?.config.id)

          debug 'debugInfo', debugFromNodeId, '->', debugToNodeId
          debug 'throttle response:', fromNodeId, '->', toNodeId, ':', JSON.stringify(msg.message, null, 2)
          return unless msg?.message?.topic == 'debug'
          return unless msg?.metadata?.fromNodeId
          node = translate(msg.message?.payload?.node)
          debug 'checking output to ', node, "(#{msg.message?.payload?.node})"
          return unless node == 'Debug-Throttle'
          # debug 'throttle response:', msg.metadata.fromNodeId, '->', msg.metadata.toNodeId, ':', JSON.stringify(msg.message, null, 2)
          @throttleMessages.push msg.message.payload.msg
        throttleStream.on 'finish', =>
          debug 'throttleStream finished'
          maybeFinish()
          sendThrottle()

      doThrottleInterval = =>
        @throttleInterval = setInterval sendThrottle, 3000

      testIt = =>
        debug "trigger initializing sut #{@times}"
        @sut.initialize =>
          # setTimeout doThrottleInterval, 3000
          debug 'sut initialized'
          @messages = []
          @responseStream = @sut.triggerByName name: 'Trigger'
          @responseStream.on 'data', (msg) =>
            msg = _.cloneDeep msg
            fromNodeId = translate(msg.metadata.fromNodeId)
            toNodeId = translate(msg.metadata.toNodeId)
            fromId = msg.message?.payload?.from
            msg.message.payload.fromName = translate fromId if fromId

            debugFromNodeId = translate(msg.metadata.debugInfo?.fromNode?.config.id)
            debugToNodeId = translate(msg.metadata.debugInfo?.toNode?.config.id)

            debug 'debugInfo', debugFromNodeId, '->', debugToNodeId
            debug 'trigger response:', fromNodeId, '->', toNodeId, ':', JSON.stringify(msg.message, null, 2)
            return unless msg?.message?.topic == 'debug'
            return unless msg?.metadata?.fromNodeId
            node = translate(msg.message?.payload?.node)
            debug 'response checking output to ', node, "(#{msg.message?.payload?.node})"
            # return unless node == 'Debug-Multiplex' or node == 'Debug-Throttle'
            debug 'response:', fromNodeId, '->', toNodeId, ':', JSON.stringify(msg.message, null, 2)
            @messages.push msg
          @responseStream.on 'finish', =>
            sendThrottle()
            debug 'responseStream finished'

      testIt()

    it "Should have the right number length of debugs", ->
      console.log '!'
      expect(@throttleMessages.length).to.equals MAX_TIMES
