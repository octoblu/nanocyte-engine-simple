debug = require('debug')('nanocyte-engine-simple:messages-controller')
InputNode = require '../models/input-node'

class MessagesController
  constructor: (options={}) ->
    {@InputNode} = options
    @InputNode ?= InputNode

  create: (req, res) =>
    inputNode = new @InputNode
    debug 'meshbluAuth', req.meshbluAuth
    @inputNode ?= new InputNode

    unless process.env.DISABLE_MESHBLU_AUTH
      unless req.meshbluAuth.uuid == req.params.flowId
        return res.status(403).end()

    req.body.flowId     = req.params.flowId
    req.body.instanceId = req.params.instanceId
    inputNode.onMessage req.body
    res.status(201).end()

module.exports = MessagesController
