InputNode = require '../models/input-node'

module.exports =
  onMessage: (message) ->
    inputNode = new InputNode
    inputNode.onMessage message
