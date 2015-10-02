{Transform} = require 'stream'
_ = require 'lodash'

class ErrorStream extends Transform
  constructor: (options) ->
    super objectMode: true
    {@error} = options

  _transform: (envelope, enc, next=->) =>
    @push _.extend {}, envelope,
      fromNodeId: envelope.toNodeId
      toNodeId:   'engine-debug'
      message: @error.message
      msgType: 'error'
    @push null

module.exports = ErrorStream
