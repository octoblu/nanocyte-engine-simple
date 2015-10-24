_      = require 'lodash'
path   = require 'path'

Router = require '../../../src/models/router'
NodeAssembler = require '../../../src/models/node-assembler'

{flowId, instanceId, config} = require path.join __dirname, './compose-race-condition-config.json'

class JsonDatastore
  constructor: (@config) ->
  hget: (key, field, callback) =>
    callback null, @config[field]

jsonDatastore = new JsonDatastore config

console.log "firing up router"
router = new Router flowId, instanceId, datastore: jsonDatastore


HANDSHAKE_TRIGGER = 'a1c90ab0-7a14-11e5-82b6-e142987dbe9c'

router.initialize =>
  console.log "router initialized."
  router.message
    metadata:
      fromNodeId: 'a1c90ab0-7a14-11e5-82b6-e142987dbe9c'
      flowId: flowId
      instanceId: instanceId
    message:
      hi: "mom"
