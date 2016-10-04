_ = require 'lodash'
{Transform} = require 'stream'
christacheio = require 'christacheio'

class ChristacheioStream extends Transform
  constructor: ({@flowId, @originalMessage, @metadata}) ->
    super objectMode: true

  _transform: ({config, data, message, metadata={}}, enc, next) =>
    {bluprint} = metadata
    if config.templateOriginalMessage
      context = _.defaults {msg: @originalMessage, @flowId, @metadata, bluprint}, @originalMessage
    else
      context = _.defaults {msg: message, @flowId, @metadata, bluprint}, message

    options = {recurseDepth:10}
    newConfig = christacheio config, context, options

    @push config: newConfig, data: data, message: message, metadata: @metadata
    next()

module.exports = ChristacheioStream
