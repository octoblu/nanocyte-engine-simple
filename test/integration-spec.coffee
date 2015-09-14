async = require 'async'
redis = require 'redis'

describe 'a flow with one trigger connected to a debug', ->
  beforeEach ->
    @client = redis.createClient()

  beforeEach (done) ->
    data = JSON.stringify
      'some-trigger-uuid':
        type: 'nanocyte-node-trigger'
        linkedTo: ['some-debug-uuid']
      'some-debug-uuid':
        type: 'nanocyte-node-debug'
        linkedTo: ['meshblu-output']
      'meshblu-output':
        type: 'meshblu-output'
        linkedTo: []

    @client.set 'some-flow-uuid/router/config', data, done

  beforeEach (done) ->
    data = JSON.stringify {}
    @client.set 'some-flow-uuid/some-trigger-uuid/config', data, done

  beforeEach (done) ->
    data = JSON.stringify {}
    @client.set 'some-flow-uuid/some-debug-uuid/config', data, done

  beforeEach (done) ->
    data = JSON.stringify {}
    @client.set 'some-flow-uuid/meshblu-output/config', data, done

  afterEach (done) ->
    async.parallel [
      (done) => @client.del 'some-flow-uuid/router/config', done
      (done) => @client.del 'some-flow-uuid/some-trigger-uuid/config', done
      (done) => @client.del 'some-flow-uuid/some-debug-uuid/config', done
      (done) => @client.del 'some-flow-uuid/meshblu-output/config', done
    ], done

  describe 'sending a message to a trigger node', ->
    beforeEach ->
      @triggerNodeOnMessage = sinon.spy => @triggerNodeOnMessage.done()

      @TriggerNode = require '../src/models/unwrapped-trigger-node-to-be-replaced'
      @originalTriggerNodeOnMessage = @TriggerNode.prototype.onMessage
      @TriggerNode.prototype.onMessage = @triggerNodeOnMessage

      @response =
        status: sinon.spy => @response
        end: sinon.spy => @respons

      MessagesController = require '../src/controllers/messages-controller'
      @sut = new MessagesController

    afterEach ->
      @TriggerNode.prototype.onMessage = @originalTriggerNodeOnMessage

    describe 'when /flows/:flowId/messages receives a message', ->
      beforeEach (done) ->
        request =
          params:
            flowId: 'some-flow-uuid'
          body:
            topic: 'button'
            devices: ['some-flow-uuid']
            payload:
              from: 'some-trigger-uuid'
              params:
                foo: 'bar'

        @triggerNodeOnMessage.done = done
        @sut.create request, @response

      it 'should call onMessage on the triggerNode', ->
        expect(@triggerNodeOnMessage).to.have.been.calledWith params: {foo: 'bar'}

      it 'should call response.status with a 201 and send', ->
        expect(@response.status).to.have.been.calledWith 201
        expect(@response.end).to.have.been.called

    describe 'when /flows/some-flow-uuid/messages receives a different message', ->
      beforeEach (done) ->
        request =
          params:
            flowId: 'some-flow-uuid'
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
      @inputHandler = require '../src/handlers/input-handler'

      @triggerNodeOnMessage = sinon.stub()

      @TriggerNode = require '../src/models/unwrapped-trigger-node-to-be-replaced'
      @originalTriggerNodeOnMessage = @TriggerNode.prototype.onMessage
      @TriggerNode.prototype.onMessage = @triggerNodeOnMessage

      @debugNodeOnMessage = sinon.spy => done()

      @DebugNode = require '../src/models/unwrapped-debug-node-to-be-replaced'
      @originalDebugNodeOnMessage = @DebugNode.prototype.onMessage
      @DebugNode.prototype.onMessage = @debugNodeOnMessage

      @triggerNodeOnMessage.yields null,
        flowId: 'some-flow-uuid'
        nodeId: 'some-trigger-uuid'
        message: {parmesian: 123456}

      @inputHandler.onMessage
        topic: 'button'
        devices: ['some-flow-uuid']
        flowId: 'some-flow-uuid'
        payload:
          from: 'some-trigger-uuid'
          parmesian: 123456

    afterEach ->
      @TriggerNode.onMessage = @originalTriggerNodeOnMessage
      @DebugNode.onMessage = @originalDebugNodeOnMessage

    it 'should call onMessage on the debug node', ->
      expect(@debugNodeOnMessage).to.have.been.calledWith parmesian: 123456

  xdescribe 'stay tuned for more words nodeId our debug node -> meshblu', ->
    beforeEach ->
      @meshbluHttpMessage = sinon.spy()

      MeshbluHttp = require 'meshblu-http'
      MeshbluHttp.prototype.message = @meshbluHttpMessage

      @debugNode = require '../src/models/unwrapped-debug-node-to-be-replaced'
      sinon.stub(@debugNode, 'onMessage').yields null,
        flowId: 'some-flow-uuid'
        nodeId: 'some-debug-uuid'
        message:
          something: 'completely-different'

      @triggerNode = require '../src/models/unwrapped-trigger-node-to-be-replaced'
      sinon.stub(@triggerNode, 'onMessage').yields null,
        flowId: 'some-flow-uuid'
        nodeId: 'some-trigger-uuid'
        message:
          something: 'completely-different'

      @inputHandler = require '../src/handlers/input-handler'
      @inputHandler.onMessage({})

    afterEach ->
      @triggerNode.onMessage.restore()
      @debugNode.onMessage.restore()

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
