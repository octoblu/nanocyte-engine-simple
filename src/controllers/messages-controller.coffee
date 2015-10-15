debug = require('debug')('nanocyte-engine-simple:messages-controller')
EngineInput = require '../models/engine-input'
child_process = require 'child_process'

class MessagesController
  constructor: (options={}) ->
    {@EngineInput} = options
    @EngineInput ?= EngineInput

  create: (req, res) =>
    debug 'meshbluAuth', req.meshbluAuth

    unless process.env.DISABLE_MESHBLU_AUTH
      unless req.meshbluAuth.uuid == req.params.flowId
        return res.status(403).end()
    res.status(201).end()

    req.body.flowId     = req.params.flowId
    req.body.instanceId = req.params.instanceId

    cylinder = child_process.fork './src/models/cylinder.js'
    cylinder.on 'exit', => console.log "Cylinder shut down"
    cylinder.send req.body

module.exports = MessagesController
