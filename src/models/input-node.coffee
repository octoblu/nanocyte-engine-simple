_ = require 'lodash'

class InputNode
  constructor: ->
    @triggerNode = require './unwrapped-trigger-node-to-be-replaced'

  onMessage: (message) =>
    payload = _.omit message.payload, 'from'
    @triggerNode.onMessage payload

module.exports =
  onMessage: (message) ->
    inputNode = new InputNode
    inputNode.onMessage message
