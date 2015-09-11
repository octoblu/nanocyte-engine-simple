_ = require 'lodash'

class InputNode
  constructor: (dependencies={}) ->
    @router = dependencies.router ? require './router'
    @triggerNode = require './unwrapped-trigger-node-to-be-replaced'

  onMessage: (message) =>
    payload = _.omit message.payload, 'from'

    @triggerNode.onMessage payload, (error, envelope) =>
      return console.error error.message if error?
      @router.onMessage envelope

module.exports = InputNode
