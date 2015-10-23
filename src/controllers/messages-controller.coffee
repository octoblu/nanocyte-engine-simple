debug = require('debug')('nanocyte-engine-simple:messages-controller')
EngineInput = require '../models/engine-input'

class MessagesController
  constructor: (options={}) ->
    {@EngineInput} = options
    @EngineInput ?= EngineInput

  create: (req, res) =>
    unless process.env.DISABLE_MESHBLU_AUTH
      unless req.header('X-MESHBLU-UUID') == req.params.flowId
        return res.status(403).end()
    res.status(201).end()

    engineInput = new @EngineInput
    req.body.flowId     = req.params.flowId
    req.body.instanceId = req.params.instanceId
    engineInput.onMessage req.body

module.exports = MessagesController
