_            = require 'lodash'
json3        = require 'json3'
{Transform}  = require 'stream'
christacheio = require 'christacheio'
debug        = require('debug')('nanocyte-engine-simple:nanocyte-node-wrapper')
Domain       = require 'domain'

class NanocyteNodeWrapper extends Transform
  constructor: (options={}) ->
    {@nodeClass} = options
    super objectMode: true

    @domain = Domain.create()
    @domain.on 'error', (error) =>
      @domain.exit()
      @emit 'error', error
      @domain.enter()

  initialize: =>
    @domain.enter()

    try
      @node = new @nodeClass
    catch error
      @emit 'error', error
      return

    @node.on 'data', (message) =>
      return if _.isNull message
      {toNodeId} = @envelope
      @push _.defaults {fromNodeId: toNodeId, message: message}, _.omit(@envelope, 'toNodeId')

    @node.on 'end', => @push null

    @node.on 'error', (error) => @emit 'error', error

    @domain.exit()

  _transform: (envelope, enc, next) =>
    @envelope = _.omit envelope, 'config', 'data'
    {config, data, message} = envelope

    firstPass = @firstPass config, message
    secondPass = @secondPass firstPass, message

    @domain.enter()
    newEnvelope = config: JSON.parse(secondPass), message: message, data: data

    delete envelope.config

    secondPass = ""

    @node.write newEnvelope, enc, => next()

    @domain.exit()

  firstPass: (config, message) =>
    message = _.defaults {msg: message}, message
    options = {tags: ['"{{', '}}"'], transformation: json3.stringify}
    christacheio json3.stringify(config), message, options

  secondPass: (templatedConfig, message) =>
    message = _.defaults {msg: message}, message
    christacheio templatedConfig, message, transformation: @escapeDoubleQuote

  escapeDoubleQuote: (data) =>
    return unless data?
    return data.toString().replace /"/g, '\\"'

module.exports = NanocyteNodeWrapper
