_ = require 'lodash'

class InputNode
  constructor: ->
    @outputHandler = require '../handlers/output-handler'
    @triggerNode = require './unwrapped-trigger-node-to-be-replaced'
    @debugNode = require './unwrapped-debug-node-to-be-replaced'

  onMessage: (message) =>
    payload = _.omit message.payload, 'from'

    @triggerNode.onMessage payload, (error, envelope) =>
      return console.error error.message if error?
      @debugNode.onMessage envelope, (error, envelope) =>
        @outputHandler.onMessage envelope

module.exports = InputNode
