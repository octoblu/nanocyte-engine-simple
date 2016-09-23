Bluprint         = require '../src/models/bluprint'
triggerRuntime = require './data/trigger-runtime.json'

describe 'Bluprint', ->
  context 'applyConfigToRuntime', ->
    it 'should return the new runtime', ->
      configSchema =
        type: 'object'
        properties:
          whatKindaTriggerDoYouWant:
            type: 'string'
            "x-node-map": [
              {id: '2bcc3810-29cc-11e6-9a5e-732530c82857', property: 'payloadType'}
            ]

      config =
        whatKindaTriggerDoYouWant: 'warning'

      sut = new Bluprint
      newRuntime = sut.applyConfigToRuntime {
        runtime: triggerRuntime,
        configSchema: configSchema,
        config: config
      }

      expect(newRuntime).to.containSubset payloadType: 'warning'


  context '->_applyConfigToEngineInput', ->
    it 'should return the new runtime', ->
      engineInputRuntime =
        'old-device-1': [
          { nodeId: 'wrong-one' }
          { nodeId: 'the-node-id' }
        ]
        'old-device-2':[
          { nodeId: 'differ' }
        ]

      configSchema =
        type: 'object'
        properties:
          hueLight:
            type: 'string'
            "x-node-map": [
              {id: 'the-node-id', property: 'uuid'}
              {id: 'wrong-one', property: 'uuid'}
            ]

      config =
        hueLight: 'the-device-uuid'

      sut = new Bluprint
      newRuntime = sut._applyConfigToEngineInput {
        runtime: engineInputRuntime,
        configSchema: configSchema,
        config: config
      }
      expected =
        'the-device-uuid': [
          { nodeId: 'wrong-one' }
          { nodeId: 'the-node-id' }
        ]
        'old-device-2':[
          { nodeId: 'differ' }
        ]
      expect(newRuntime).to.deep.equal expected
