morgan             = require 'morgan'
express            = require 'express'
bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
meshbluAuth        = require 'express-meshblu-auth'
MeshbluConfig      = require 'meshblu-config'
debug              = require('debug')('nanocyte-engine-simple:server')

require 'heapdump'

MessagesController = require './src/controllers/messages-controller'
messagesController = new MessagesController

PORT  = process.env.PORT ? 80
meshbluConfig = new MeshbluConfig
debug 'meshbluConfig', meshbluConfig.toJSON()

app = express()
app.use morgan('dev', immediate: true)
app.use errorHandler()
app.use meshbluHealthcheck()
app.use meshbluAuth meshbluConfig.toJSON() unless process.env.DISABLE_MESHBLU_AUTH == 'true'
app.use bodyParser.urlencoded limit: '50mb', extended : true
app.use bodyParser.json limit : '50mb'

app.post '/flows/:flowId/instances/:instanceId/messages', messagesController.create

server = app.listen PORT, ->
  host = server.address().address
  port = server.address().port

  console.log "Server running on #{host}:#{port}"
