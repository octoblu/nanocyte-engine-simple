debug = require('debug')('nanocyte-engine-simple:messages-controller')

class MessagesController
  constructor: (options={}) ->
    {@inputNode} = options
    @inputNode ?= new (require '../models/input-node')

  create: (req, res) =>
    debug 'meshbluAuth', req.meshbluAuth
    return res.status(403).end() unless req.meshbluAuth.uuid == req.params.flowId
    req.body.flowId     = req.params.flowId
    req.body.instanceId = req.params.instanceId
    @inputNode.onMessage(req.body)
    res.status(201).end()

module.exports = MessagesController
