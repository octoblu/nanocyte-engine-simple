_ = require 'lodash'

class InputNode
  constructor: ->
    @triggerNode = require './unwrapped-trigger-node-to-be-replaced'
    @debugNode = require './unwrapped-debug-node-to-be-replaced'

  onMessage: (message) =>
    payload = _.omit message.payload, 'from'
    @triggerNode.onMessage payload, @debugNode.onMessage


module.exports = InputNode
