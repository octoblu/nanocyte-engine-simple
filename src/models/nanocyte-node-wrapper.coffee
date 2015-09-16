_ = require 'lodash'
{Transform} = require 'stream'

class NanocyteNodeWrapper extends Transform
  constructor: ({nodeClass}) ->
    super objectMode: true
    
    @node = new nodeClass
    @node.on 'readable', =>
      message = @node.read()
      envelope  = _.omit @envelope, 'config', 'data'
      @push _.extend {}, envelope, message: message

    @node.on 'end', => @push null

  _transform: (@envelope, enc, next) =>
    newEnvelope = _.cloneDeep _.pick(@envelope, 'config', 'data', 'message')
    @node.write newEnvelope, enc, next

module.exports = NanocyteNodeWrapper
