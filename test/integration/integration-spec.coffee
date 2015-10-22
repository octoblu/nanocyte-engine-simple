stream = require 'stream'
path = require 'path'
async = require 'async'
redis = require 'redis'
_ = require 'lodash'
debug = require('debug')('nanoparticle')

fakeOutComponent = (packageName, onWrite) ->
  class FakeNode extends stream.Transform
    constructor: ->
      super objectMode: true

    _transform: (envelope, encoding, next=->) =>
      onWrite envelope, (error, newEnvelope) =>
        @push newEnvelope
        @push null

      next()

  require packageName

  theModule = require.cache[path.join(__dirname, '../../node_modules', packageName, 'index.js')]
  theModule.exports = FakeNode
  theModule.original = theModule.exports.prototype

restoreComponent = (packageName) ->
  theModule = require.cache[path.join(__dirname, '../../node_modules', packageName, 'index.js')]
  theModule.exports = theModule.original

describe 'a flow with one trigger connected to a debug', ->
  beforeEach ->
    @client = redis.createClient()

    @response =
      status: sinon.spy => @response
      end: sinon.spy => @response

  beforeEach (done) ->
    data = JSON.stringify
      'engine-input':
        type: 'engine-input'
        transactionGroupId: 'engine-input-group-id'
        linkedTo: ['some-trigger-uuid']
      'some-trigger-uuid':
        type: 'nanocyte-component-trigger'
        transactionGroupId: 'trigger-group-id'
        linkedTo: ['some-debug-uuid']
      'some-debug-uuid':
        type: 'nanocyte-component-pass-through'
        transactionGroupId: 'debug-group-id'
        linkedTo: ['engine-debug']
      'engine-debug':
        type: 'engine-debug'
        transactionGroupId: 'engine-debug-group-id'
        linkedTo: []

    @client.hset 'some-flow-uuid', 'instance-uuid/router/config', data, done

  beforeEach (done) ->
    data = JSON.stringify {'some-debug-uuid': {toNodeId: 'original-debug-uuid'}}
    @client.hset 'some-flow-uuid', 'instance-uuid/engine-debug/config', data, done

  beforeEach (done) ->
    data = JSON.stringify {uuid: 'some-flow-uuid', token: 'some-token'}
    @client.hset 'some-flow-uuid', 'instance-uuid/engine-output/config', data, done

  beforeEach (done) ->
    data = JSON.stringify {}
    @client.hset 'some-flow-uuid', 'instance-uuid/engine-data/config', data, done

  beforeEach (done) ->
    data = JSON.stringify {}
    @client.hset 'some-flow-uuid', 'instance-uuid/some-trigger-uuid/config', data, done

  beforeEach (done) ->
    data = JSON.stringify {}
    @client.hset 'some-flow-uuid', 'instance-uuid/some-debug-uuid/config', data, done

  beforeEach (done) ->
    data = JSON.stringify {}
    @client.setex 'pulse:some-flow-uuid', 300, '', done

  afterEach (done) ->
    async.parallel [
      (done) => @client.del 'some-flow-uuid/instance-uuid/router/config', done
      (done) => @client.del 'some-flow-uuid/instance-uuid/engine-debug/config', done
      (done) => @client.del 'some-flow-uuid/instance-uuid/engine-output/config', done
      (done) => @client.del 'some-flow-uuid/instance-uuid/some-trigger-uuid/config', done
      (done) => @client.del 'some-flow-uuid/instance-uuid/some-debug-uuid/config', done
    ], done

  describe 'sending a message to a trigger node', ->
    beforeEach ->
      @timeout 4000
      @triggerNodeOnMessage = sinon.spy => @triggerNodeOnMessage.done()
      fakeOutComponent 'nanocyte-component-trigger', @triggerNodeOnMessage

      MessagesController = require '../../src/controllers/messages-controller'
      @sut = new MessagesController

    afterEach ->
      restoreComponent 'nanocyte-component-trigger'

    describe 'when /flows/:flowId/instances/:instanceId/messages receives a message', ->
      beforeEach (done) ->
        request =
          params:
            flowId: 'some-flow-uuid'
            instanceId: 'instance-uuid'
          meshbluAuth:
            uuid: 'some-flow-uuid'
          body:
            topic: 'button'
            devices: ['some-flow-uuid']
            payload:
              from: 'engine-input'
              params:
                foo: 'bar'

        @triggerNodeOnMessage.done = done
        debug '@sut.create'
        @sut.create request, @response

      it 'should call onMessage on the triggerNode', ->
        expect(@triggerNodeOnMessage).to.have.been.calledWith
          config: {}
          data: null
          message:
            topic: 'button'
            payload:
              params:
                foo: 'bar'

      it 'should call response.status with a 201 and send', ->
        expect(@response.status).to.have.been.calledWith 201
        expect(@response.end).to.have.been.called

    describe 'when /flows/:flowId/instances/:instanceId/messages receives a different message', ->
      beforeEach (done) ->
        request =
          params:
            flowId: 'some-flow-uuid'
            instanceId: 'instance-uuid'
          meshbluAuth:
            uuid: 'some-flow-uuid'
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
            topic: 'button'
            payload:
              parmesian:
                something: 'completely-different'

      it 'should call response.status with a 201 and send', ->
        expect(@response.status).to.have.been.calledWith 201
        expect(@response.end).to.have.been.called

  describe 'and now a word from trigger, to the debug node', ->
    beforeEach (done) ->
      @triggerNodeWrite = sinon.stub().yields null, parmesian: 123456
      @debugNodeWrite = sinon.spy =>
        done()

      fakeOutComponent 'nanocyte-component-pass-through', @debugNodeWrite
      fakeOutComponent 'nanocyte-component-trigger', @triggerNodeWrite

      MessagesController = require '../../src/controllers/messages-controller'
      @sut = new MessagesController

      request =
        params:
          flowId: 'some-flow-uuid'
          instanceId: 'instance-uuid'
        meshbluAuth:
          uuid: 'some-flow-uuid'
        body:
          topic: 'button'
          devices: ['some-flow-uuid']
          payload:
            from: 'engine-input'
            params:
              parmesian: 123456

      @sut.create request, @response

    afterEach ->
      restoreComponent 'nanocyte-component-pass-through'
      restoreComponent 'nanocyte-component-trigger'

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
      MeshbluHttp.prototype.message = @meshbluHttpMessage

      @debugOnWrite = sinon.stub().yields null, something: 'completely-different'
      @triggerOnWrite = sinon.stub().yields null, something: 'completely-different'

      fakeOutComponent 'nanocyte-component-pass-through', @debugOnWrite
      fakeOutComponent 'nanocyte-component-trigger', @triggerOnWrite

      MessagesController = require '../../src/controllers/messages-controller'
      @sut = new MessagesController

      request =
        params:
          flowId: 'some-flow-uuid'
          instanceId: 'instance-uuid'
        meshbluAuth:
          uuid: 'some-flow-uuid'
        body:
          topic: 'button'
          devices: ['some-flow-uuid']
          payload:
            from: 'engine-input'
            params:
              foo: 'bar'

      @sut.create request, @response

    afterEach ->
      restoreComponent 'nanocyte-component-pass-through'
      restoreComponent 'nanocyte-component-trigger'

    it 'should call message on a MeshbluHttp instance', ->
      expect(@meshbluHttpMessage).to.have.been.calledOnce
      expect(@meshbluHttpMessage).to.have.been.calledWith
        devices: ['*']
        topic: 'message-batch'
        payload:
          messages: [{
            devices: ['*']
            topic: 'debug'
            payload:
              node: "original-debug-uuid",
              msgType: undefined
              msg: something: 'completely-different'
          }]
