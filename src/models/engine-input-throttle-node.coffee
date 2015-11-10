EngineInputNode = require './engine-input-node'
EngineInputThrottle = require './engine-input-throttle'

class EngineInputThrottleNode extends EngineInputNode
  constructor: (dependencies={}) ->
    dependencies.EngineInput ?= EngineInputThrottle
    super dependencies

module.exports = EngineInputThrottleNode
