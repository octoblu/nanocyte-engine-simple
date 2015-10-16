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
    
  _transform: (@envelope, enc, next) =>
    @domain.enter()
    try
      node = new @nodeClass
    catch error
      @emit 'error', error
    return
    @node.on 'data', (message) =>

      @node.on 'readable', =>
        message = @node.read()
        return if _.isNull message

        {toNodeId} = @envelope
        envelope  = _.omit @envelope, 'config', 'data', 'toNodeId'
        @push _.defaults {fromNodeId: toNodeId, message: message}, envelope

      @node.on 'end', => @push null

      @node.on 'error', (error) =>
        @emit 'error', error

      @domain.exit()

    newEnvelope = _.pick(@envelope, 'config', 'data', 'message')
    {config,message} = newEnvelope

    firstPass = @firstPass config, message
    secondPass = @secondPass firstPass, message
    newEnvelope.config = json3.parse secondPass

    @domain.enter()
    @node.write newEnvelope, enc, =>
      next()
    @domain.exit()

  firstPass: (json, context) =>
    context = _.defaults {msg: context}, context
    options = {tags: ['"{{', '}}"'], transformation: json3.stringify}
    christacheio json3.stringify(json), context, options

  secondPass: (str,context) =>
    context = _.defaults {msg: context}, context
    christacheio str, context, transformation: @escapeDoubleQuote

  escapeDoubleQuote: (data) =>
    return unless data?
    return data.toString().replace /"/g, '\\"'

module.exports = NanocyteNodeWrapper
