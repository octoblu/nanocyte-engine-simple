{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:flow-time-stream')

FlowTime = require './flow-time'
class FlowTimeStream extends Transform
  constructor: ({@flowTime}, dependencies={}) ->
    super objectMode: true

  _transform: (message, enc, next) =>
    return if @shuttingDown
    
    unless @flowTime?
      debug "no flowTime in metadata. not gonna check it"
      @push message unless @shuttingDown
      return next()

    @flowTime.addTimedOut (error, timedOut) =>
      if timedOut
        debug "timed out. killing myself"
        @shutdown()
        return next new Error("timed out.")

      @push message unless @shuttingDown
      next()

  shutdown: =>
    return if @shuttingDown
    @shuttingDown = true
    @push null

module.exports = FlowTimeStream
