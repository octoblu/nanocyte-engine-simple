debug = require('debug')('nanocyte-engine-simple:messages-controller')
EngineInput = require '../models/engine-input'

class MessagesController
  constructor: (options={}) ->
    {@EngineInput} = options
    @EngineInput ?= EngineInput

  create: (req, res, options) =>
    debug 'meshbluAuth', req.meshbluAuth

    unless process.env.DISABLE_MESHBLU_AUTH
      unless req.meshbluAuth.uuid == req.params.flowId
        return res.status(403).end()
    res.status(201).end()

    engineInput = new @EngineInput
    req.body.flowId     = req.params.flowId
    req.body.instanceId = req.params.instanceId

    return engineInput.message req.body

module.exports = MessagesController
