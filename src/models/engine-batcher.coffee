async = require 'async'
EngineOutputNode = require './engine-output-node'

class EngineBatcher
  constructor: ->
    @batches = {}
    @interval = setInterval @flushAll, 100

  push: (key, envelope) =>
    {metadata, message} = envelope
    @batches[key] ?= metadata: metadata, messages: []
    @batches[key].messages.push message

  flush: (key, callback) =>
    @_sendMessage key, callback

  flushAll: =>
    async.eachSeries _.keys(@batches), (key, done) =>
      @_sendMessage key, done

  _sendMessage: (key, callback) =>
    data = @batches[key]
    return callback new Error "batch not found for #{key}" unless data?

    engineOutputNode = new EngineOutputNode
    message =
      devices: ['*']
      topic: 'message-batch'
      payload:
        messages: data.messages

    engineOutputNode.message message
    engineOutputNode.on 'finish', => callback()

module.exports = new EngineBatcher
