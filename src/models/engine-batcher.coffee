_ = require 'lodash'
async = require 'async'
debug = require('debug')('nanocyte-engine-simple:engine-batcher')
EngineOutputNode = require './engine-output-node'

class EngineBatcher
  constructor: (@options, @dependencies) ->
    @batches = {}
    @flushAllInterval = setInterval @_flushAll, 100

  push: (key, envelope) =>
    {metadata, message} = envelope
    @batches[key] ?= metadata: metadata, messages: []
    @batches[key].messages.push message

  waitFlushAll: (callback) =>
    return setImmediate @waitFlushAll, callback if @flushing
    @_flushAll callback

  shutdownFlushAll: (callback) =>
    clearInterval @flushAllInterval
    @waitFlushAll callback

  _flushAll: (callback=->) =>
    return callback() if @flushing
    @flushing = true
    async.eachSeries _.keys(@batches), @_flush, =>
      @flushing = false
      callback()

  _flush: (key, callback) =>
    data = @batches[key]
    return callback() unless data?
    delete @batches[key]

    engineOutputNode = new EngineOutputNode @options, @dependencies
    message =
      devices: ['*']
      topic: 'message-batch'
      payload:
        messages: data.messages

    metadata = _.clone data.metadata
    metadata.toNodeId = 'engine-output'

    engineOutputNode.sendEnvelope({metadata,message}).on 'finish', callback

module.exports = EngineBatcher
