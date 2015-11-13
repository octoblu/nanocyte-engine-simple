_ = require 'lodash'
debug = require('debug')('bad-throttle')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
MAX_TIMES = 2
DEBUG_TIMES= 6
describe 'BadThrottle', ->
  @timeout 300000
  describe 'when instantiated with a flow', ->

    beforeEach ->
      @flow = require './flows/bad-throttle.json'
      @nodes = _.map @flow.nodes, (val)=>
        return _.pick val, ['id','name','uuid']
      # console.log 'here are my nodes:', JSON.stringify(@nodes, null, 2)

    beforeEach (done) ->
      @times = 0
      @failure = false

      translate = (id)=>
        filter = _.filter(@nodes,{id:id})?[0]
        # console.log 'translated', id, 'to', filter
        return filter?.name or id

      maybeFinish = =>
        @times++
        @engineDebugs = _.filter @messages, (message) =>
          message.metadata.toNodeId == 'engine-debug'
        # if @engineDebugs.length != DEBUG_TIMES
        #   @failure = true
        #   return done()
        return done() if @times == MAX_TIMES
        # testIt()

      sendThrottle = =>
        throttle = new EngineInAVat flowName: 'bad-throttle', flowData: @flow
        throttle.initialize =>
          debug 'sut initialized'
          throttleId = filter = _.filter(@nodes,{name:"Throttle"})?[0].id
          console.log 'using throttleId:', throttleId
          @throttleTimes++
          @throttleMessages = []
          throttleStream = throttle.messageEngine throttleId
          throttleStream.on 'data', (msg) =>
            fromNodeId = translate(msg.metadata.fromNodeId)
            toNodeId = translate(msg.metadata.toNodeId)
            # console.log 'throttle response:', fromNodeId, '->', toNodeId, ':', JSON.stringify(msg.message, null, 2)
            return unless msg?.message?.topic == 'debug'
            return unless msg?.metadata?.fromNodeId
            node = translate(msg.message?.payload?.node)
            console.log 'checking output to ', node, "(#{msg.message?.payload?.node})"
            return unless node == 'Debug-Multiplex' or node == 'Debug-Throttle'
            # console.log 'throttle response:', msg.metadata.fromNodeId, '->', msg.metadata.toNodeId, ':', JSON.stringify(msg.message, null, 2)
            @throttleMessages.push msg
          throttleStream.on 'finish', =>
            console.log 'throttleStream finished'
            maybeFinish()

      testIt = =>
        debug "initializing sut #{@times}"
        debug process.memoryUsage()
        @sut = new EngineInAVat flowName: 'bad-throttle', flowData: @flow
        @sut.initialize =>
          @throttleInterval = setInterval sendThrottle, 1000
          debug 'sut initialized'
          @messages = []
          @responseStream = @sut.triggerByName name: 'Trigger'
          @responseStream.on 'data', (msg) =>
            fromNodeId = translate(msg.metadata.fromNodeId)
            toNodeId = translate(msg.metadata.toNodeId)
            # console.log 'response:', fromNodeId, '->', toNodeId, ':', JSON.stringify(msg.message, null, 2)
            return unless msg?.message?.topic == 'debug'
            return unless msg?.metadata?.fromNodeId
            node = translate(msg.message?.payload?.node)
            console.log 'response checking output to ', node, "(#{msg.message?.payload?.node})"
            # return unless node == 'Debug-Multiplex' or node == 'Debug-Throttle'
            console.log 'response:', fromNodeId, '->', toNodeId, ':', JSON.stringify(msg.message, null, 2)
            @messages.push msg
          @responseStream.on 'finish', =>
            console.log 'responseStream finished'

      testIt()

    it "Should kill maybe around 1000 messages", ->
      expect(@messages.length).to.be.at.most 1100
