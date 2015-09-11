_ = require 'lodash'

class Router
  constructor: (dependencies={}) ->
    {@datastore} = dependencies

  onMessage: (envelope) =>
    debugNode = require './unwrapped-debug-node-to-be-replaced'
    @datastore.get envelope.flowId, (error, flow) =>
      links = _.where flow.links, from: envelope.nodeId
      _.each links, (link) =>
        debugNode.onMessage envelope.message

module.exports = Router
