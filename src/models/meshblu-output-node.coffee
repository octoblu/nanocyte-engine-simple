class MeshbluOutputNode
  constructor: (dependencies={}) ->
    @MeshbluHttp = require 'meshblu-http'
    Datastore = require './datastore'
    {@datastore} = dependencies
    @datastore ?= new Datastore

  onMessage: (envelope) =>
    @datastore.get "#{envelope.flowId}/#{envelope.instanceId}/engine-output/config", (error, config) =>
      meshbluHttp = new @MeshbluHttp config
      meshbluHttp.message
        devices: [envelope.flowId]
        topic: 'debug'
        payload:
          node: envelope.fromNodeId,
          msg:
            payload:
              envelope.message

module.exports = MeshbluOutputNode
