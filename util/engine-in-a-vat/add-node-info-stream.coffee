_ = require 'lodash'
debug = require('debug')('engine-in-a-vat:add-node-info-stream')
{Transform} = require 'stream'

class AddNodeInfoStream extends Transform
  constructor: ({@flowData, @nanocyteConfig})->
    super objectMode: true
    @on 'finish', => debug "I'm dead now, so grateful"

  _transform: (envelope, enc, next) =>
    return @push null unless envelope?
    fromNode = @nanocyteConfig[envelope.metadata.fromNodeId]
    toNode = @nanocyteConfig[envelope.metadata.toNodeId]
    debugInfo =
      fromNode: fromNode
      toNode: toNode
      timestamp: Date.now()
      nanocyteType: envelope.metadata.nanocyteType

    _.extend envelope.metadata, debugInfo: debugInfo
    @push envelope
    next()

module.exports = AddNodeInfoStream
