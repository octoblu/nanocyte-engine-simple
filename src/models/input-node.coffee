_         = require 'lodash'
Datastore = require './datastore'
Router    = require './router'

class InputNode
  constructor: (options, dependencies={}) ->
    {@datastore,@router} = dependencies
    @datastore ?= new Datastore
    @router    ?= new Router

  onMessage: (message) =>
    @_getFromNodeIds message, (error, fromNodeIds) =>
      return console.error error.stack if error?
      return console.error 'inputNode could not infer fromNodeId' if _.isEmpty fromNodeIds

      payload = _.cloneDeep(message.payload ? {})
      delete payload.from

      _.each fromNodeIds, (fromNodeId) =>
        @router.onEnvelope
          flowId:     message.flowId
          instanceId: message.instanceId
          fromNodeId: fromNodeId
          message:    payload

  _getFromNodeIds: (message, callback) =>
    fromNodeId = message.payload?.from
    return callback null, [fromNodeId] if fromNodeId?

    {flowId,instanceId,fromUuid} = message
    @datastore.hget flowId, "#{instanceId}/engine-input/config", (error, config) =>
      return callback error if error?
      return callback null unless config?
      callback null, _.pluck config[fromUuid], 'nodeId'

module.exports = InputNode
