_ = require 'lodash'
debug = require('debug')('engine-in-a-vat:add-node-info-stream')
{Transform} = require 'stream'

class AddNodeInfoStream extends Transform
  constructor: ({@flowData, @nanocyteConfig})->
    super objectMode: true
    @on 'finish', => debug "I'm dead now, so grateful"

  _transform: (envelope, enc, next) =>
    fromNode = @nanocyteConfig[envelope?.metadata?.fromNodeId]
    toNode = @nanocyteConfig[envelope?.metadata?.toNodeId]
    debugInfo =
      fromNode: fromNode
      toNode: toNode
      timestamp: Date.now()
      nanocyteType: envelope.metadata?.nanocyteType

    debugEnvelope = _.extend {}, envelope
    debugEnvelope.metadata ?= {}
    _.extend debugEnvelope.metadata, debugInfo: debugInfo

    @push debugEnvelope
    next()

module.exports = AddNodeInfoStream
