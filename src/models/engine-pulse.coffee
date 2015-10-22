{Transform} = require 'stream'

class EnginePulse extends Transform
  constructor: (options={}) ->
    {@fromNodeId} = options
    super objectMode: true

  _transform: ({config, data, message}, enc, next) =>
    # console.log "PULSE CONFIG: ", config
    @push
      devices: ['*']
      topic: 'pulse'
      payload:
        node: config[@fromNodeId]?.toNodeId

    next()

module.exports = EnginePulse
