stream = require 'stream'
path = require 'path'
async = require 'async'
redis = require 'redis'
_ = require 'lodash'

fakeOutNode = (packageName, onWrite) ->
  class FakeNode extends stream.Transform
    constructor: ->
      super objectMode: true

    _transform: (envelope, encoding, next=->) =>
      onWrite envelope, =>
        @push envelope.message

      next()

  require packageName

  theModule = require.cache[path.join(__dirname, '../../node_modules', packageName, 'index.js')]
  theModule.exports = FakeNode
  theModule.original = theModule.exports.prototype

restoreNode = (packageName) ->
  theModule = require.cache[path.join(__dirname, '../../node_modules', packageName, 'index.js')]
  theModule.exports = theModule.original

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
    data = JSON.stringify {uuid: 'some-flow-uuid', token: 'some-token'}
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
      fakeOutNode 'nanocyte-node-trigger', @triggerNodeOnMessage

      @response =
        status: sinon.spy => @response
        end: sinon.spy => @response

      MessagesController = require '../../src/controllers/messages-controller'
      @sut = new MessagesController

    afterEach ->
      restoreNode 'nanocyte-node-trigger'

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
              from: 'engine-input'
              params:
                foo: 'bar'

        @triggerNodeOnMessage.done = done
        @sut.create request, @response

      it 'should call onMessage on the triggerNode', ->
        expect(@triggerNodeOnMessage).to.have.been.calledWith
          config: {}
          data: null
          message:
            params: {foo: 'bar'}

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
              from: 'engine-input'
              parmesian: {
                something: 'completely-different'
              }

        @triggerNodeOnMessage.done = done
        @sut.create request, @response

      it 'should call onMessage on the triggerNode', ->
        expect(@triggerNodeOnMessage).to.have.been.calledWith
          config: {}
          data: null
          message:
            parmesian: {something: 'completely-different'}

      it 'should call response.status with a 201 and send', ->
        expect(@response.status).to.have.been.calledWith 201
        expect(@response.end).to.have.been.called

  describe 'and now a word from trigger, to the debug node', ->
    beforeEach (done) ->
      @inputHandler = require '../../src/handlers/input-handler'

      @triggerNodeWrite = sinon.stub().yields parmesian: 123456
      @debugNodeWrite = sinon.spy =>
        done()

      fakeOutNode 'nanocyte-node-debug', @debugNodeWrite
      fakeOutNode 'nanocyte-node-trigger', @triggerNodeWrite

      @inputHandler.onMessage
        topic: 'button'
        devices: ['some-flow-uuid']
        flowId: 'some-flow-uuid'
        instanceId: 'instance-uuid'
        payload:
          from: 'some-trigger-uuid'
          parmesian: 123456

    afterEach ->
      restoreNode 'nanocyte-node-debug'
      restoreNode 'nanocyte-node-trigger'

    it 'should write the message to the debug node', ->
      expect(@debugNodeWrite).to.have.been.calledWith
        config: {}
        data: null
        message: { parmesian: 123456 }

  describe 'stay tuned for more words from our debug node -> meshblu', ->
    beforeEach (done) ->
      @meshbluHttpMessage = sinon.spy =>
        done()

      MeshbluHttp = require 'meshblu-http'
      console.log 'overwriting it'
      MeshbluHttp.prototype.message = @meshbluHttpMessage

      @debugOnWrite = sinon.stub().yields something: 'completely-different'
      @triggerOnWrite = sinon.stub().yields()

      fakeOutNode 'nanocyte-node-debug', @debugOnWrite
      fakeOutNode 'nanocyte-node-trigger', @triggerOnWrite

      @inputHandler = require '../../src/handlers/input-handler'
      @inputHandler.onMessage
        devices: ['some-flow-uuid']
        flowId: 'some-flow-uuid'
        instanceId: 'instance-uuid'
        payload:
          from: 'some-trigger-uuid'
          something: 'completely-different'

    afterEach ->
      restoreNode 'nanocyte-node-debug'
      restoreNode 'nanocyte-node-trigger'

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
