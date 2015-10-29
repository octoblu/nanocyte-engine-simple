debug = require('debug')('nanocyte-engine-simple:messages-controller')
EngineInputNode = require '../models/engine-input-node'

class MessagesController
  constructor: (options={}) ->
    {@EngineInputNode} = options
    @EngineInputNode ?= EngineInputNode

  create: (req, res) =>
    debug 'meshbluAuth', req.meshbluAuth
    unless process.env.DISABLE_MESHBLU_AUTH
      unless req.header('X-MESHBLU-UUID') == req.params.flowId
        return res.status(403).end()
    res.status(201).end()

    engineInput = new @EngineInputNode

    inputStream = engineInput.message
      metadata:
        flowId: req.params.flowId
        instanceId: req.params.instanceId
      message: req.body

    inputStream.on 'finish', => console.log "router is done!"

module.exports = MessagesController
