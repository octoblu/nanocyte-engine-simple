class MessageCounter
  constructor: ->
    @streamCount = 0

  add: =>
    @streamCount++

  subtract: =>
    @streamCount--
    @callback() if @streamCount == 0

  onDone: (@callback) =>

module.exports = MessageCounter
