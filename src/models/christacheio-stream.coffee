_ = require 'lodash'
{Transform} = require 'stream'
christacheio = require 'christacheio'

class ChristacheioStream extends Transform
  constructor: ({@flowId, @originalMessage, @metadata}) ->
    super objectMode: true

  _transform: ({config, data, message}, enc, next) =>
    if config.templateOriginalMessage
      firstPass = @firstPass config, @originalMessage
    else
      firstPass = @firstPass config, message

    secondPass = @secondPass firstPass, message
    newConfig = JSON.parse secondPass
    @push config: newConfig, data: data, message: message, metadata: @metadata
    next()

  firstPass: (json, context) =>
    context = _.defaults {msg: context, @flowId, @metadata}, context
    options = {tags: ['"{{', '}}"'], transformation: JSON.stringify}
    christacheio JSON.stringify(json), context, options

  secondPass: (str,context) =>
    context = _.defaults {msg: context, @flowId, @metadata}, context
    christacheio str, context, transformation: @escapeDoubleQuote

  escapeDoubleQuote: (data) =>
    return unless data?
    return data.toString().replace /"/g, '\\"'

module.exports = ChristacheioStream
