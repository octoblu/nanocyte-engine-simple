_ = require 'lodash'
{PassThrough,Writable} = require 'stream'

class NanocyteNodeWrapper extends Writable
  constructor: ({nodeClass}) ->
    super objectMode: true
    @node = new nodeClass

    @messageOutStream = new PassThrough objectMode: true
    @node.messageOutStream.on 'readable', =>
      {message} = @node.messageOutStream.read()
      envelope  = _.omit @envelope, 'config', 'data'

      @messageOutStream.write _.extend {}, envelope, message: message

  _write: (@envelope, enc, next) =>
    newEnvelope = _.cloneDeep _.pick(@envelope, 'config', 'data', 'message')
    @node.write newEnvelope, enc, next


module.exports = NanocyteNodeWrapper
