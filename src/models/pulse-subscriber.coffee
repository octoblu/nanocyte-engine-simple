Datastore = require './datastore'

class PulseSubscriber
  constructor: (options, dependencies={}) ->
    {@datastore} = dependencies
    @datastore ?= new Datastore

  subscribe: (flowId) =>
    @datastore.setex "#{flowId}-pulse", 300

module.exports = PulseSubscriber
