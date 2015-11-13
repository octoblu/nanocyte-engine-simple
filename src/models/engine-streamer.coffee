mergeStream = require 'merge-stream'

class EngineStreamer
  constructor: ->
    @stream = mergeStream()

  add: (stream) =>
    @stream.add stream

module.exports = new EngineStreamer
