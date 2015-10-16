_                   = require 'lodash'
async               = require 'async'
Datastore           = require './datastore'
Router              = require './router'
PulseSubscriber     = require './pulse-subscriber'
ProcessCountManager = require './process-count-manager'
debug               = require('debug')('nanocyte-engine-simple:engine-input')

class EngineInput
  constructor: (options, dependencies={}) ->
    {@datastore,@router,@pulseSubscriber} = dependencies
    @datastore ?= new Datastore
    @router    ?= new Router
    @pulseSubscriber ?= new PulseSubscriber

  onMessage: (message) =>
    debug 'onMessage:', fromUuid: message.fromUuid
    if message.topic == 'subscribe:pulse'
      @pulseSubscriber.subscribe message.flowId
      return
    endCallback = =>
      debug 'everything is done!'

    processCountManager = new ProcessCountManager endCallback, class: 'engine-input'
    processCountManager.up()
    @_getFromNodeIds message, (error, fromNodeIds) =>
      return console.error error.stack if error?
      return console.error 'engineInput could not infer fromNodeId' if _.isEmpty fromNodeIds

      flowId = message.flowId
      instanceId = message.instanceId
      message = _.omit message, 'devices', 'flowId', 'instanceId'
      delete message?.payload?.from

      eachCallback = (fromNodeId, next) =>
        processCountManager.up()
        envelopeMessage =
          flowId:     flowId
          instanceId: instanceId
          fromNodeId: fromNodeId
          message:    message
        @router.onEnvelope envelopeMessage, (error) =>
          debug 'done with envelopeMessage'
          processCountManager.down()
          next error
      endEachCallback = (error) =>
        console.error error if error?
        debug 'done with message'
        processCountManager.down()
        processCountManager.checkZero()

      async.each fromNodeIds, eachCallback, endEachCallback


  _getFromNodeIds: (message, callback) =>
    fromNodeId = message.payload?.from
    return callback null, [fromNodeId] if fromNodeId?

    {flowId,instanceId,fromUuid} = message
    @datastore.hget flowId, "#{instanceId}/engine-input/config", (error, config) =>
      return callback error if error?
      return callback null unless config?
      callback null, _.pluck config[fromUuid], 'nodeId'

module.exports = EngineInput
