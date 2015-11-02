stream = require 'stream'
path   = require 'path'
async  = require 'async'
redis  = require 'redis'
_      = require 'lodash'
debug  = require('debug')('nanocyte-engine-simple:engine-runner')
client = require '../../src/handlers/redis-handler'
class EngineRunner
  before: (done=->) =>
    @client = client

    data = JSON.stringify @ENGINE_CONFIG
    @client.hset @FLOW_UUID, 'instance-uuid/router/config', data, done

  after: (done=->) =>
    _.defer done

module.exports = EngineRunner
