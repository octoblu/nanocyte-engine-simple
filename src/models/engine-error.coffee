EngineRouterNode = require './engine-router-node'

class EngineError
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

    router = new Router
    router.stream.on 'finish', callback
    router.message errorMessage

module.exports = EngineError
