class MeshbluOutputNode
  constructor: (dependencies={}) ->
    @MeshbluHttp = require 'meshblu-http'
    Datastore = require './datastore'
    {@datastore} = dependencies
    @datastore ?= new Datastore

  onMessage: (envelope) =>
    @datastore.get "#{envelope.flowId}/b028a0f0-5cca-11e5-ba53-cbe60492eee3/meshblu-output/config", (error, config) =>
      console.log "OutputNode's config is:"
      console.log JSON.stringify config, null, 2
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
