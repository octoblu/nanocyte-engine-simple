debug = require('debug')('nanocyte-engine-simple:messages-controller')
InputNode = require '../models/input-node'

class MessagesController
  constructor: (options={}) ->
    {@InputNode} = options
    @InputNode ?= InputNode
  create: (req, res) =>
    inputNode = new @InputNode
    console.log "create called"
    debug 'meshbluAuth', req.meshbluAuth

    unless process.env.DISABLE_MESHBLU_AUTH
      unless req.meshbluAuth.uuid == req.params.flowId
        return res.status(403).end()

    req.body.flowId     = req.params.flowId
    req.body.instanceId = req.params.instanceId
    console.log "onMessage called with", req.body
    inputNode.onMessage req.body
    res.status(201).end()

module.exports = MessagesController
