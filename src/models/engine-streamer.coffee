mergeStream = require 'merge-stream'

class EngineStreamer
  constructor: ->
    @streamCount = 0

  add: =>
    @streamCount++
    console.log "added. streamCount is now #{@streamCount}"

  subtract: =>
    @streamCount--
    console.log "subtracted. streamCount is now #{@streamCount}"
    # @callback() if @streamCount == 0

  onDone: (@callback)=>

module.exports = new EngineStreamer
