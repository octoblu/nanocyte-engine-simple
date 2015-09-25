_         = require 'lodash'
Datastore = require './datastore'
Router    = require './router'

class InputNode
  constructor: (options, dependencies={}) ->
    {@datastore,@router} = dependencies
    @datastore ?= new Datastore
    @router    ?= new Router

  onMessage: (message, callback=->) =>
    @_getFromNodeId message, (error, fromNodeId) =>
      return console.error error.stack if error?
      return console.error 'inputNode could not infer fromNodeId' unless fromNodeId?
      payload = _.omit message.payload, 'from'

      @router.onEnvelope
        flowId:     message.flowId
        instanceId: message.instanceId
        fromNodeId: fromNodeId
        message:    payload

  _getFromNodeId: (message, callback) =>
    fromNodeId = message.payload?.from
    return callback null, fromNodeId if fromNodeId?

    {flowId,instanceId,fromUuid} = message
    @datastore.get "#{flowId}/#{instanceId}/engine-input/config", (error, config) =>
      return callback error if error?
      callback null, config[fromUuid]?.nodeId

module.exports = InputNode
