_                = require 'lodash'
Router           = require '../../src/models/router'
NodeAssembler    = require '../../src/models/node-assembler'
EngineOutputNode = require '../../src/models/engine-output-node'

debugStream = require('debug-stream')('nanocyte-router-runner')
debug = require('debug')('nanocyte-router-runner')

class RunnerOutputNode extends EngineOutputNode
  constructor: -> super EngineOutput: debugStream

class RunnerNodeAssembler extends NodeAssembler
  constructor: (options)-> super options, EngineOutputNode: RunnerOutputNode

class JsonDatastore
  constructor: (@config) ->

  hget: (key, field, callback) =>
    callback null, @config[field]

class RouterRunner
  constructor: ({@flowId, @instanceId, @config}) ->
    @jsonDatastore = new JsonDatastore @config
    @routerDependencies = datastore: @jsonDatastore, NodeAssembler: RunnerNodeAssembler

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

    router = new Router @flowId, @instanceId, @routerDependencies

    router.initialize =>
      debug "router initialized."
      router.message envelope

  findTriggerIdByName: (triggerName) =>
    trigger = _.findWhere @config, {name: triggerName, type: 'operation:trigger'}
    return trigger?.id

  module.exports = RouterRunner
