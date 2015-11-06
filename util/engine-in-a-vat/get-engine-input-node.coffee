{Transform} = require 'stream'
_ = require 'lodash'
debug = require('debug')('engine-in-a-vat:node-assembler')

NodeAssembler = require('../../src/models/node-assembler')
EngineInput = require '../../src/models/engine-input'
EngineInputNode = require '../../src/models/engine-input-node'
EngineRouterNode = require '../../src/models/engine-router-node'

getVatEngineInput = (outputStream) ->
  class VatNodeAssembler extends NodeAssembler
    assembleNodes: =>
      nodes = _.mapValues super, getVatNode
      nodes['engine-output'] = nodes['nanocyte-component-pass-through']

      nodes

  getVatNode = (RealNode, nanocyteType)->
    class VatNode extends RealNode
      constructor: ->
        super
      _getEnvelopeStream: (envelope) =>
        envelope.metadata.nanocyteType = nanocyteType
        outputStream.write envelope if envelope?
        super envelope

  class VatEngineRouterNode extends EngineRouterNode
    constructor: (dependencies={}) ->
      assembler = new VatNodeAssembler
      nodes = assembler.assembleNodes()
      dependencies.nodes = nodes
      super dependencies

    _getEnvelopeStream: (envelope) =>
      outputStream.write envelope if envelope?
      super envelope

  class VatEngineInput extends EngineInput
    constructor: (options, dependencies={}) ->
      dependencies.EngineRouterNode = VatEngineRouterNode
      super options, dependencies

  class VatEngineInputNode extends EngineInputNode
    constructor: (dependencies={}) ->
      dependencies.EngineInput = VatEngineInput
      super dependencies


  return VatEngineInputNode


module.exports = getVatEngineInput
