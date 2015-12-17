_ = require 'lodash'
async = require 'async'
debug = require('debug')('nanocyte-engine-simple:engine-batcher')
EngineOutputNode = require './engine-output-node'

class EngineBatcher
  constructor: (@options, @dependencies) ->
    @batches = {}
    @flushAllInterval = setInterval @flushAll, 100
    @processing = {}
    @callbacks = {}

  push: (key, envelope) =>
    {metadata, message} = envelope
    @batches[key] ?= metadata: metadata, messages: []
    @batches[key].messages.push message

  _shutdownFlushAll: (callback) =>
    unless @flushing
      clearInterval @shutdownInterval
      @flushAll callback

  shutdownFlushAll: (callback=->) =>
    clearInterval @flushAllInterval
    @shutdownInterval = setInterval @_shutdownFlushAll, 50, callback
    @_shutdownFlushAll callback

  flushAll: (callback=->) =>
    return callback() if @flushing
    @flushing = true
    async.eachSeries _.keys(@batches), (key, done) =>
      @_sendMessage key, done
    , =>
      @flushing = false
      callback()

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
      callback()

module.exports = EngineBatcher
