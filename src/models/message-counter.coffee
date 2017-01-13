debug = (require 'debug')('nanocyte-engine-simple:message-counter')

class MessageCounter
  constructor: ->
    @reset()

  reset: =>
    @max = 0
    @streamCount = 0

  add: =>
    @streamCount++
    @max = @streamCount if @max < @streamCount
    debug "adding to #{@streamCount}"

  subtract: =>
    @streamCount--
    debug "subtracting to #{@streamCount}"
    @callback() if @streamCount == 0

  onDone: (@callback) =>

module.exports = MessageCounter
