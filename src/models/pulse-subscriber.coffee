Datastore = require './datastore'
debug = require('debug')('nanocyte-engine-simple:pulse-subscriber')

class PulseSubscriber
  constructor: (options, dependencies={}) ->
    {@datastore} = dependencies
    @datastore ?= new Datastore

  subscribe: (flowId) =>
    debug flowId
    @datastore.setex "pulse:#{flowId}", 300, '', =>

module.exports = PulseSubscriber
