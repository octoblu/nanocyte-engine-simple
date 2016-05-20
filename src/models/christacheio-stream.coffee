_ = require 'lodash'
{Transform} = require 'stream'
christacheio = require 'christacheio'

class ChristacheioStream extends Transform
  constructor: ({@flowId, @originalMessage, @metadata}) ->
    super objectMode: true

  _transform: ({config, data, message}, enc, next) =>
    context = _.defaults {msg: @originalMessage, @flowId, @metadata}, @originalMessage
    options = {recurseDepth:10}
    newConfig = christacheio config, context, options

    @push config: newConfig, data: data, message: message, metadata: @metadata
    next()

module.exports = ChristacheioStream
