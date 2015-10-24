stream = require 'stream'
path = require 'path'
async = require 'async'
redis = require 'redis'
_ = require 'lodash'
debug = require('debug')('nanoparticle')

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
      'engine-output':
        type: 'engine-output'
        linkedTo: []

    @client.hset 'some-flow-uuid', 'instance-uuid/router/config', data, done

  beforeEach (done) ->
    data = JSON.stringify {'some-debug-uuid': {nodeId: 'original-debug-uuid'}}
    @client.hset 'some-flow-uuid', 'instance-uuid/engine-debug/config', data, done

  beforeEach (done) ->
    data = JSON.stringify {uuid: 'some-flow-uuid', token: 'some-token'}
    @client.hset 'some-flow-uuid', 'instance-uuid/engine-output/config', data, done

  beforeEach (done) ->
    data = JSON.stringify {}
    @client.hset 'some-flow-uuid', 'instance-uuid/engine-data/config', data, done

  beforeEach (done) ->
    data = JSON.stringify payload: "{{msg.payload}}"
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
      MessagesController = require '../../src/controllers/messages-controller'
      @sut = new MessagesController

    describe 'when /flows/:flowId/instances/:instanceId/messages receives a message', ->
      beforeEach (done) ->
        @messages = []

        request =
          header: sinon.stub().returns 'some-flow-uuid'
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

        routerStream = @sut.create request, @response

        routerStream.on 'data', (message) => @messages.push message
        routerStream.on 'end', done

      it 'should cause the trigger node to output a message', ->
        expect(@messages).to.containSubset [{
          metadata:
            fromNodeId: 'some-trigger-uuid'
          message:
            payload:
              params:
                foo: 'bar'
        }]

      it 'should call response.status with a 201 and send', ->
        expect(@response.status).to.have.been.calledWith 201
        expect(@response.end).to.have.been.called

    describe 'when /flows/:flowId/instances/:instanceId/messages receives a different message', ->
      beforeEach (done) ->
        @messages = []
        request =
          header: sinon.stub().returns 'some-flow-uuid'
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

        @messageStream = @sut.create request, @response
        @messageStream.on 'data', (message) => @messages.push message
        @messageStream.on 'finish', => done()

      it 'should call message on the triggerNode', ->
        expect(@messages).to.containSubset [{
          metadata:
            flowId: 'some-flow-uuid'
            instanceId: 'instance-uuid'
            fromNodeId: 'some-trigger-uuid'
          message:
            payload:
              parmesian:
                something: 'completely-different'
          }]

      it 'should call response.status with a 201 and send', ->
        expect(@response.status).to.have.been.calledWith 201
        expect(@response.end).to.have.been.called

  describe 'and now a word from trigger, to the debug node', ->
    beforeEach (done) ->
      MessagesController = require '../../src/controllers/messages-controller'
      @sut = new MessagesController
      @messages = []
      request =
        header: sinon.stub().returns 'some-flow-uuid'
        params:
          flowId: 'some-flow-uuid'
          instanceId: 'instance-uuid'
        body:
          topic: 'button'
          devices: ['some-flow-uuid']
          payload:
            from: 'engine-input'
            params:
              parmesian: 123456

      routerStream = @sut.create request, @response
      routerStream.on 'data', (message) => @messages.push message
      routerStream.on 'end', done

    it 'should cause the debug node to emit a message', ->
      expect(@messages).to.containSubset [{
          metadata:
            fromNodeId: 'some-debug-uuid'
          message:
            payload:
              params:
                parmesian: 123456
        }]


  describe 'stay tuned for more words from our debug node -> meshblu', ->
    beforeEach (done) ->
      MessagesController = require '../../src/controllers/messages-controller'
      @sut = new MessagesController

      request =
        header: sinon.stub().returns 'some-flow-uuid'
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

      @messages = []
      routerStream = @sut.create request, @response
      routerStream.on 'data', (message) => @messages.push message
      routerStream.on 'end', done

    it 'should call cause engine-debug to emit a message', ->
        expect(@messages).to.containSubset [{
          metadata:
            fromNodeId: 'engine-debug'
          message:
            devices: [ '*' ]
            topic: 'message-batch'
            payload:
              messages: [
                {
                  devices: [
                    "*"
                  ]
                  payload:
                    msg:
                      payload:
                        params:
                          foo: "bar"
                    node: "original-debug-uuid"
                }
              ]
        }]
