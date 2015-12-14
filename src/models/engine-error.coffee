EngineRouterNode = require './engine-router-node'

class EngineError
  constructor: (@options, @dependencies) ->

  @sendError: (error, callback, Router=EngineRouterNode) =>
    console.log "Sending error: #{error}"
    errorMessage =
      metadata:
        toNodeId: 'router'
        fromNodeId: 'engine-error'
        flowId: @flowId
        instanceId: @instanceId
        msgType: 'error'
      message: error.message

    router = new Router @options, @dependencies
    router.stream.on 'finish', callback
    router.message errorMessage

module.exports = EngineError
