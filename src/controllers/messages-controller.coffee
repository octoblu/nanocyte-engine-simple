class MessagesController
  constructor: (options={}) ->
    {@inputNode} = options
    @inputNode ?= require '../models/input-node'

  create: (req, res) =>
    @inputNode.onMessage(req.body)
    res.status(201).end()

module.exports = MessagesController
