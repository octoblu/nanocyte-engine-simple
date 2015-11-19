{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-batch')
_ = require 'lodash'
EngineBatcher = require './engine-batcher'
class EngineBatch extends Transform
  constructor: (@metadata) ->
    super objectMode: true
    {@flowId, instanceId} = @metadata

  _transform: (message, enc, next) =>
    EngineBatcher.push @flowId, metadata: @metadata, message: message
    @push null
    next()

module.exports = EngineBatch
