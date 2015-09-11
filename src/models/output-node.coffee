class OutputNode
  constructor: ->
    @MeshbluHttp = require 'meshblu-http'

  onMessage: (envelope) =>
    meshbluHttp = new @MeshbluHttp
    meshbluHttp.message
      topic: 'debug'
      devices: ['some-flow-uuid']
      payload:
        node: envelope.from
        msg:
          payload:
            envelope.message


module.exports = OutputNode
