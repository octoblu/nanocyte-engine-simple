{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-batch')
_ = require 'lodash'

class EngineBatch extends Transform
  constructor: (@metadata, dependencies) ->
    super objectMode: true
    {@flowId, instanceId} = @metadata
    {@engineBatcher} = dependencies

  _transform: (message, enc, next=->) =>
    debug 'transforming engineBatch!'
    @engineBatcher.push @flowId, metadata: @metadata, message: message
    @push null
    next()

module.exports = EngineBatch
