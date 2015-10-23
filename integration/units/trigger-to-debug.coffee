_                  = require 'lodash'
async              = require 'async'
SendingTrigger     = require '../classes/trigger-component'
MessagesController = require '../../src/controllers/messages-controller'

class TriggerToDebug extends SendingTrigger
  constructor: ->
    @label = "TriggerToDebug"
    @FLOW_UUID = 'some-flow-uuid'
    @ENGINE_CONFIG =
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

  before: (done=->) =>
    super =>
      async.parallel [
        (done) =>
          data = JSON.stringify {'some-debug-uuid': {toNodeId: 'original-debug-uuid'}}
          @client.hset 'some-flow-uuid', 'instance-uuid/engine-debug/config', data, done
        (done) =>
          data = JSON.stringify {uuid: 'some-flow-uuid', token: 'some-token'}
          @client.hset 'some-flow-uuid', 'instance-uuid/engine-output/config', data, done
        (done) =>
          data = JSON.stringify {}
          @client.hset 'some-flow-uuid', 'instance-uuid/engine-data/config', data, done
        (done) =>
          data = JSON.stringify {}
          @client.hset 'some-flow-uuid', 'instance-uuid/some-trigger-uuid/config', data, done
        (done) =>
          data = JSON.stringify {}
          @client.hset 'some-flow-uuid', 'instance-uuid/some-debug-uuid/config', data, done
        (done) =>
          data = JSON.stringify {}
          @client.setex 'pulse:some-flow-uuid', 300, '', done
      ], done

  run: (done=->) =>
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

    response = {}
    response.status = => response
    response.end = => response
    @triggerNodemessage.done = done
    @sut = new MessagesController
    @sut.create request, response

  after: (done=->) =>
    super =>
      async.parallel [
        (done) => @client.del @FLOW_UUID + '/instance-uuid/router/config', done
        (done) => @client.del @FLOW_UUID + '/instance-uuid/engine-debug/config', done
        (done) => @client.del @FLOW_UUID + '/instance-uuid/engine-output/config', done
        (done) => @client.del @FLOW_UUID + '/instance-uuid/some-trigger-uuid/config', done
        (done) => @client.del @FLOW_UUID + '/instance-uuid/some-debug-uuid/config', done
      ], done

module.exports = TriggerToDebug
