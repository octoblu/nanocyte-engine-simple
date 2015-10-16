stream = require 'stream'
path   = require 'path'
async  = require 'async'
redis  = require 'redis'
_      = require 'lodash'
debug  = require('debug')('nanocyte-engine-simple:engine-runner')

class EngineRunner
  before: (done=->) =>
    @client = redis.createClient()

    data = JSON.stringify @ENGINE_CONFIG
    @client.hset @FLOW_UUID, 'instance-uuid/router/config', data, done

  after: (done=->) =>
    _.defer done

  fakeOutComponent: (packageName, onWrite) =>
    class FakeNode extends stream.Transform
      constructor: ->
        super objectMode: true

      _transform: (envelope, encoding, next=->) =>
        onWrite envelope, (error, newEnvelope) =>
          @push newEnvelope
          @push null

        next()

    require packageName

    theModule = require.cache[path.join(__dirname, '../../node_modules', packageName, 'index.js')]
    theModule.exports = FakeNode
    theModule.original = theModule.exports.prototype

  restoreComponent: (packageName) =>
    theModule = require.cache[path.join(__dirname, '../../node_modules', packageName, 'index.js')]
    theModule.exports = theModule.original

module.exports = EngineRunner
