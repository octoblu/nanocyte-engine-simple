class MeshbluOutputNode
  constructor: (dependencies={}) ->
    @MeshbluHttp = require 'meshblu-http'
    Datastore = require './datastore'
    {@datastore} = dependencies
    @datastore ?= new Datastore

  onMessage: (envelope) =>
    @datastore.get "#{envelope.flowId}/meshblu-output/config", (error, config) =>
      meshbluHttp = new @MeshbluHttp config
      meshbluHttp.message
        devices: [envelope.flowId]
        topic: 'debug'
        payload:
          node: "some-debug-uuid",
          msg:
            payload:
              envelope.message

module.exports = MeshbluOutputNode
