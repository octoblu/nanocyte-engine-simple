morgan = require 'morgan'
express = require 'express'
bodyParser = require 'body-parser'
errorHandler = require 'errorhandler'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
debug = require('debug')('nanocyte-engine-simple')

MessagesController = require './src/controllers/messages-controller'
messagesController = new MessagesController

PORT  = process.env.PORT ? 80

app = express()
app.use morgan 'dev'
app.use errorHandler()
app.use meshbluHealthcheck()
app.use bodyParser.urlencoded limit: '50mb', extended : true
app.use bodyParser.json limit : '50mb'

app.post '/flows/:flowId/instances/:instanceId/messages', messagesController.create

server = app.listen PORT, ->
  host = server.address().address
  port = server.address().port

  console.log "Server running on #{host}:#{port}"
