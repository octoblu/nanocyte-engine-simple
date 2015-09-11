OutputNode = require '../models/output-node'

module.exports =
  onMessage: (envelope) ->
    outputNode = new OutputNode
    outputNode.onMessage envelope
