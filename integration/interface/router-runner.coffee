_             = require 'lodash'
async         = require 'async'
{PassThrough} = require 'stream'
redisHandler  = require '../../src/handlers/redis-handler'
Router        = require '../../src/models/router'

debugStream   = require('debug-stream')('nanocyte-router-runner')
debug         = require('debug')('nanocyte-router-runner')

class RouterRunner
  constructor: ({@flowId, @instanceId, @config}) ->

  initialize: (callback) =>
    configKeys = _.keys @config
    setKey = (key, done) =>
      data = JSON.stringify @config[key]
      debug "setting #{key}"
      redisHandler.hset @flowId, key, data, done

    async.each configKeys, setKey, (error) =>
      return callback error if error?
      redisHandler.set "pulse:#{@flowId}", 1, callback

  done: (callback) =>
    configKeys = _.keys @config
    unsetKey = (key, done) =>
      data = JSON.stringify @config[key]    
      redisHandler.hdel @flowId, key, data, done

  triggerByName: (triggerName, message, callback) =>
    triggerId = @findTriggerIdByName triggerName
    return callback new Error "Can't find a trigger named '#{triggerName}'" unless triggerId?
    @messageRouter triggerId, message, callback

  messageRouter: (nodeId, message, callback) =>
    envelope =
      metadata:
        fromNodeId: nodeId
        flowId: @flowId
        instanceId: @instanceId
      message: message

    router = new Router @flowId, @instanceId

    router.initialize =>
      debug "router initialized."
      router.message envelope
      router.on 'end', => process.exit -1
      router.on 'data', (data) => debug "router said:", data

    router

  findTriggerIdByName: (triggerName) =>
    trigger = _.findWhere @config, {name: triggerName, type: 'operation:trigger'}
    return trigger?.id

  module.exports = RouterRunner
