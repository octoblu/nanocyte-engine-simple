_ = require 'lodash'
Router = require './router'

class InputNode
  constructor: (dependencies={}) ->
    @router = dependencies.router ? new Router
    @triggerNode = require './unwrapped-trigger-node-to-be-replaced'

  onMessage: (message) =>
    payload = _.omit message.payload, 'from'

    @triggerNode.onMessage payload, (error, envelope) =>
      return console.error error.message if error?
      @router.onMessage envelope

module.exports = InputNode
