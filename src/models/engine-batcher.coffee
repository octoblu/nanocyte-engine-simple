_ = require 'lodash'
async = require 'async'
debug = require('debug')('nanocyte-engine-simple:engine-batcher')
EngineOutputNode = require './engine-output-node'

class EngineBatcher
  constructor: (@options, @dependencies) ->
    @batches = {}
    @interval = setInterval @_flushAll, 50, 'interval'
    @processing = {}
    @callbacks = {}

  push: (key, envelope) =>
    {metadata, message} = envelope
    @batches[key] ?= metadata: metadata, messages: []
    @batches[key].messages.push message

  flush: (key, callback) =>
    debug 'flush', key
    @_sendMessage key, callback

  clearFlushAll: (callback=->) =>
    @shutdown = true
    clearInterval @interval
    @_flushAll 'shutdown', callback, true

  _flushAll: (msg, callback=(->), shutdown=false) =>
    console.log msg if msg?
    async.eachSeries _.keys(@batches), (key, done) =>
      if shutdown and @processing[key]
        @shutdownCallback = callback
        return done()
      @processing[key] = true
      console.log 'sending key', key, shutdown
      @_sendMessage key, =>
        delete @processing[key]
        done()
    , =>
      return if shutdown and @shutdownCallback?
      callback()
      @shutdownCallback() if @shutdownCallback?

  _sendMessage: (key, callback) =>
    data = @batches[key]
    return callback() unless data?

    engineOutputNode = new EngineOutputNode @options, @dependencies
    message =
      devices: ['*']
      topic: 'message-batch'
      payload:
        messages: data.messages

    metadata = _.clone data.metadata
    metadata.toNodeId = 'engine-output'

    delete @batches[key]

    stream = engineOutputNode.sendEnvelope metadata: metadata, message: message
    stream.on 'finish', =>
      debug 'engine-output finish', key
      if @batches[key]? and @shutdown
        console.log 'found more data to process'
        return setImmediate @_sendMessage, key, callback
      callback()
      @shutdownCallback() if @shutdownCallback?

module.exports = EngineBatcher
