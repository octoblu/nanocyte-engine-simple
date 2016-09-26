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
    describe 'when given a runtime, configSchema, and config', ->
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
            { nodeId: 'the-node-id' }
            { nodeId: 'wrong-one' }
          ]
          'old-device-2':[
            { nodeId: 'differ' }
          ]
        expect(newRuntime).to.deep.equal expected

describe 'when given a runtime, configSchema, and config', ->
  it 'should return the new runtime', ->
    engineInputRuntime =
      'old-device-1': [
        { nodeId: 'node-1' }
        { nodeId: 'node-2' }
      ]
      'old-device-2': [
        { nodeId: 'node-3' }
        { nodeId: 'node-4' }
      ]

    configSchema =
      type: "object"
      properties:
        room:
          type: "string"
          "x-meshblu-device-filter":
            type: "device:conference-room"
          format: "meshblu-device"
          "x-node-map": [
            {
              id: "node-3"
              property: "uuid"
            }
            {
              id: "node-4"
              property: "uuid"
            }
            {
              id: "97fcbeb0-6a45-11e6-9866-6935a2d8bb28"
              property: "right"
            }
            {
              id: "af566020-6a45-11e6-9866-6935a2d8bb28"
              property: "right"
            }
          ]
          required: false
          description: ""
        hue:
          type: "string"
          "x-meshblu-device-filter":
            type: "device:hue-light"
          format: "meshblu-device"
          "x-node-map": [
            {
              id: "node-1"
              property: "uuid"
            }
            {
              id: "node-2"
              property: "uuid"
            }
          ]

    config =
      room: "the-room"
      hue: "the-hue"

    sut = new Bluprint
    newRuntime = sut._applyConfigToEngineInput {
      runtime: engineInputRuntime,
      configSchema: configSchema,
      config: config
    }
    expected =
        'the-hue': [
          { nodeId: 'node-1' }
          { nodeId: 'node-2' }
        ]
        'the-room': [
          { nodeId: 'node-3' }
          { nodeId: 'node-4' }
        ]
    expect(newRuntime).to.deep.equal expected
