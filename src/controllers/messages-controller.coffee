class MessagesController
  constructor: (options={}) ->
    {@inputHandler} = options
    @inputHandler ?= new (require '../models/input-node')

  create: (req, res) =>
    req.body.flowId     = req.params.flowId
    req.body.instanceId = req.params.instanceId
    @inputHandler.onMessage(req.body)
    res.status(201).end()

module.exports = MessagesController
