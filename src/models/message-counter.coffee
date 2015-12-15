debug = (require 'debug')('nanocyte-engine-simple:message-counter')

class MessageCounter
  constructor: ->
    @streamCount = 0

  add: =>
    @streamCount++
    debug "adding to #{@streamCount}"

  subtract: =>
    @streamCount--
    debug "subtracting to #{@streamCount}"
    @callback() if @streamCount == 0

  onDone: (@callback) =>

module.exports = MessageCounter
