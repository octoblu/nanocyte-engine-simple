stream = require 'stream'
path = require 'path'
async = require 'async'
redis = require 'redis'
_ = require 'lodash'

fakeOutDebugNode = (onWrite=_.noop) ->
  class FakeDebugNode extends stream.Transform
    constructor: ->
      super objectMode: true

    _transform: (envelope, encoding, next=->) =>
      onWrite envelope, =>
        @push envelope.message

      next()

  require 'nanocyte-node-debug'

  debugModule = require.cache[path.join(__dirname, '../../node_modules/nanocyte-node-debug/index.js')]
  debugModule.exports = FakeDebugNode
  debugModule.original = debugModule.exports.prototype

restoreDebugNode = ->
  debugModule = require.cache[path.join(__dirname, '../../node_modules/nanocyte-node-debug/index.js')]
  debugModule.exports = debugModule.original

describe 'a flow with one trigger connected to a debug', ->
  beforeEach ->
    @client = redis.createClient()

  beforeEach (done) ->
    data = JSON.stringify
      'engine-input':
        type: 'engine-input'
        linkedTo: ['some-trigger-uuid']
      'some-trigger-uuid':
        type: 'nanocyte-node-trigger'
        linkedTo: ['some-debug-uuid']
      'some-debug-uuid':
        type: 'nanocyte-node-debug'
        linkedTo: ['engine-output']
      'engine-output':
        type: 'engine-output'
        linkedTo: []

    @client.set 'some-flow-uuid/instance-uuid/router/config', data, done

  beforeEach (done) ->
    data = JSON.stringify {}
    @client.set 'some-flow-uuid/instance-uuid/some-trigger-uuid/config', data, done

  beforeEach (done) ->
    data = JSON.stringify {}
    @client.set 'some-flow-uuid/instance-uuid/some-debug-uuid/config', data, done

  beforeEach (done) ->
    data = JSON.stringify {}
    @client.set 'some-flow-uuid/instance-uuid/engine-output/config', data, done

  afterEach (done) ->
    async.parallel [
      (done) => @client.del 'some-flow-uuid/instance-uuid/router/config', done
      (done) => @client.del 'some-flow-uuid/instance-uuid/some-trigger-uuid/config', done
      (done) => @client.del 'some-flow-uuid/instance-uuid/some-debug-uuid/config', done
      (done) => @client.del 'some-flow-uuid/instance-uuid/engine-output/config', done
    ], done

  describe 'sending a message to a trigger node', ->
    beforeEach ->
      @triggerNodeOnMessage = sinon.spy => @triggerNodeOnMessage.done()

      @TriggerNode = require 'nanocyte-node-trigger'
      @originalTriggerNodeOnMessage = @TriggerNode.prototype.onMessage
      @TriggerNode.prototype.onMessage = @triggerNodeOnMessage

      @response =
        status: sinon.spy => @response
        end: sinon.spy => @respons

      MessagesController = require '../../src/controllers/messages-controller'
      @sut = new MessagesController

    afterEach ->
      @TriggerNode.prototype.onMessage = @originalTriggerNodeOnMessage

    describe 'when /flows/:flowId/instances/:instanceId/messages receives a message', ->
      beforeEach (done) ->
        request =
          params:
            flowId: 'some-flow-uuid'
            instanceId: 'instance-uuid'
          body:
            topic: 'button'
            devices: ['some-flow-uuid']
            payload:
              from: 'some-trigger-uuid'
              params:
                foo: 'bar'

        @triggerNodeOnMessage.done = done
        @sut.create request, @response

      it.only 'should call onMessage on the triggerNode', ->
        expect(@triggerNodeOnMessage).to.have.been.calledWith params: {foo: 'bar'}

      it 'should call response.status with a 201 and send', ->
        expect(@response.status).to.have.been.calledWith 201
        expect(@response.end).to.have.been.called

    describe 'when /flows/:flowId/instances/:instanceId/messages receives a different message', ->
      beforeEach (done) ->
        request =
          params:
            flowId: 'some-flow-uuid'
            instanceId: 'instance-uuid'
          body:
            topic: 'button'
            devices: ['some-flow-uuid']
            payload:
              from: 'some-trigger-uuid'
              parmesian: {
                something: 'completely-different'
              }

        @triggerNodeOnMessage.done = done
        @sut.create request, @response

      it 'should call onMessage on the triggerNode', ->
        expect(@triggerNodeOnMessage).to.have.been.calledWith parmesian: {something: 'completely-different'}

      it 'should call response.status with a 201 and send', ->
        expect(@response.status).to.have.been.calledWith 201
        expect(@response.end).to.have.been.called

  describe 'and now a word from trigger, to the debug node', ->
    beforeEach (done) ->
      @inputHandler = require '../../src/handlers/input-handler'
      @triggerNodeOnMessage = sinon.stub()
      @TriggerNode = require 'nanocyte-node-trigger'
      @originalTriggerNodeOnMessage = @TriggerNode.prototype.onMessage
      @TriggerNode.prototype.onMessage = @triggerNodeOnMessage
      @debugNodeWrite = sinon.spy =>
        done()

      fakeOutDebugNode @debugNodeWrite
      @triggerNodeOnMessage.yields null, parmesian: 123456
      @inputHandler.onMessage
        topic: 'button'
        devices: ['some-flow-uuid']
        flowId: 'some-flow-uuid'
        instanceId: 'instance-uuid'
        payload:
          from: 'some-trigger-uuid'
          parmesian: 123456

    afterEach ->
      @TriggerNode.onMessage = @originalTriggerNodeOnMessage
      restoreDebugNode()

    it 'should write the message to the debug node', ->
      expect(@debugNodeWrite).to.have.been.calledWith
        config: {}
        data: null
        message: { parmesian: 123456 }

  describe 'stay tuned for more words from our debug node -> meshblu', ->
    beforeEach (done) ->
      @meshbluHttpMessage = sinon.spy =>
        done()
      @debugOnWrite = sinon.stub().yields()
      MeshbluHttp = require 'meshblu-http'
      MeshbluHttp.prototype.message = @meshbluHttpMessage

      @triggerNodeOnMessage = sinon.stub()

      @TriggerNode = require 'nanocyte-node-trigger'
      @originalTriggerNodeOnMessage = @TriggerNode.prototype.onMessage
      @TriggerNode.prototype.onMessage = @triggerNodeOnMessage

      fakeOutDebugNode @debugOnWrite

      @triggerNodeOnMessage.yields null,
        something: 'completely-different'

      @inputHandler = require '../../src/handlers/input-handler'
      @inputHandler.onMessage
        devices: ['some-flow-uuid']
        flowId: 'some-flow-uuid'
        instanceId: 'instance-uuid'
        payload:
          from: 'some-trigger-uuid'
          something: 'completely-different'

    afterEach ->
      @TriggerNode.onMessage = @originalTriggerNodeOnMessage
      restoreDebugNode()

    it 'should call message on a MeshbluHttp instance', ->
      expect(@meshbluHttpMessage).to.have.been.calledOnce
      expect(@meshbluHttpMessage).to.have.been.calledWith
        devices: ['some-flow-uuid']
        topic: 'debug'
        payload:
          node: "some-debug-uuid",
          msg:
            payload:
              something: 'completely-different'
