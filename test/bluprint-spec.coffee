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
