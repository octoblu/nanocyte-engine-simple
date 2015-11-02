_ = require 'lodash'
{Transform} = require 'stream'
christacheio = require 'christacheio'

class ChristacheioStream extends Transform
  constructor: (options={}) ->
    super objectMode: true

  _transform: ({config, data, message}, enc, next) =>
    firstPass = @firstPass config, message
    secondPass = @secondPass firstPass, message
    newConfig = JSON.parse secondPass
    @push config: newConfig, data: data, message: message

    next()

  firstPass: (json, context) =>
    context = _.defaults {msg: context}, context
    options = {tags: ['"{{', '}}"'], transformation: JSON.stringify}
    christacheio JSON.stringify(json), context, options

  secondPass: (str,context) =>
    context = _.defaults {msg: context}, context
    christacheio str, context, transformation: @escapeDoubleQuote

  escapeDoubleQuote: (data) =>
    return unless data?
    return data.toString().replace /"/g, '\\"'

module.exports = ChristacheioStream
