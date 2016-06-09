IotApp         = require '../src/models/iot-app'
triggerRuntime = require './data/trigger-runtime.json'

describe 'IotApp', ->
  context 'applyConfigToRuntime', ->
    it 'should return the new runtime', ->
      configSchema =
        type: 'object'
        properties:
          whatKindaTriggerDoYouWant:
            type: 'string'
            "x-node-map": [
              {id: '37f0a74a-2f17-11e4-9617-a6c5e4d22fb7', property: 'payloadType'}
            ]

      config =
        whatKindaTriggerDoYouWant: 'warning'

      sut = new IotApp
      newRuntime = sut.applyConfigToRuntime {
        runtime: triggerRuntime,
        configSchema: configSchema,
        config: config
      }

      expect(newRuntime).to.containSubset payloadType: 'warning'
