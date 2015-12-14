Datastore = require './datastore'
debug = require('debug')('nanocyte-engine-simple:pulse-subscriber')

class PulseSubscriber
  constructor: (options, dependencies={}) ->
    {@datastore} = dependencies
    @datastore ?= new Datastore options, dependencies

  subscribe: (flowId, callback=->) =>
    debug flowId
    @datastore.setex "pulse:#{flowId}", 300, '', callback

module.exports = PulseSubscriber
