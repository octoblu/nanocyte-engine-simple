module.exports =
  onMessage: =>
    MeshbluHttp = require 'meshblu-http'
    meshbluHttp = new MeshbluHttp
    meshbluHttp.message
      devices: ['some-flow-uuid']
      topic: 'debug'
      payload:
        node: "some-debug-uuid",
        msg:
          payload:
            something: 'completely-different'
