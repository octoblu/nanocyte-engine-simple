{Transform}  = require 'stream'
christacheio = require 'christacheio'
debug        = require('debug')('nanocyte-engine-simple:nanocyte-node-wrapper')
_            = require 'lodash'

class NanocyteNodeWrapper extends Transform
  constructor: ({nodeClass}) ->
    super objectMode: true

    @node = new nodeClass
    @node.on 'readable', =>
      message = @node.read()
      return if _.isNull message

      {toNodeId} = @envelope
      envelope  = _.omit @envelope, 'config', 'data', 'toNodeId'
      @push _.defaults {fromNodeId: toNodeId, message: message}, envelope

    @node.on 'end', => @push null

    @node.on 'error', (error) =>

  _transform: (@envelope, enc, next) =>
    newEnvelope = _.cloneDeep _.pick(@envelope, 'config', 'data', 'message')
    {config,message} = newEnvelope

    firstPass = @firstPass config, message
    secondPass = @secondPass firstPass, message
    newEnvelope.config = JSON.parse secondPass

    @node.write newEnvelope, enc, next

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

module.exports = NanocyteNodeWrapper
