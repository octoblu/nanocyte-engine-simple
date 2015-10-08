{Transform} = require 'stream'
_ = require 'lodash'

class EngineBatch extends Transform

  write: (envelope) ->
    EngineBatch.batches ?= {}
    EngineBatch.batches[envelope.flowId] ?= _.pick envelope, 'flowId', 'instanceId', 'toNodeId'
    EngineBatch.batches[envelope.flowId].envelopes ?= []
    EngineBatch.batches[envelope.flowId].envelopes.push envelope

module.exports = EngineBatch
