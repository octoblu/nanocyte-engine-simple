EngineOutput = require '../../src/models/engine-output'
async = require 'async'
_ = require 'lodash'

class EngineOutputFactory

  @createStreamEngineOutput: (outputStream) ->
    class VatMeshbluHttp
      constructor: (@config) ->

      message: (message, callback) =>
        messages = message?.payload?.messages if message?.topic == 'message-batch'
        async.each messages or [message], (message, next) =>
          outputStream.write _.merge({},{@config}, {message}), next
        , callback

    class StreamEngineOutput extends EngineOutput
      constructor: (@metadata, dependencies={}) ->
        dependencies.MeshbluHttp = VatMeshbluHttp
        super(@metadata, dependencies)

module.exports = EngineOutputFactory
