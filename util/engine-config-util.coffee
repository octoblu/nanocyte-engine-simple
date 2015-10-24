commander = require 'commander'
redis = require '../src/handlers/redis-handler'
_ = require 'lodash'

commander.version('1.0.0')
  .arguments '<flow-id> <flow-instance>'
  .parse process.argv

flowId = commander.args[0]
instanceId = commander.args[1]

return commander.outputHelp() unless flowId? && instanceId?

getEngineConfig = (flowId, instanceId, callback) =>
  redis.hgetall flowId, (error, data) =>
    return callback error if error?
    rawConfig = _.pick data, (value, key) => _.startsWith key, instanceId
    config = _.map rawConfig, (value, key) =>
        return JSON.parse value

    callback null, config

getEngineConfig flowId, instanceId, (error, config) =>
  console.log "config is:", JSON.stringify config, null, 2
  redis.unref()
