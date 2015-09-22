class MessagesController
  constructor: (options={}) ->
    {@inputNode} = options
    @inputNode ?= new (require '../models/input-node')

  create: (req, res) =>
    req.body.flowId     = req.params.flowId
    req.body.instanceId = req.params.instanceId
    @inputNode.onMessage(req.body)
    res.status(201).end()

module.exports = MessagesController
