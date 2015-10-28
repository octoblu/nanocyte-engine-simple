{Transform} = require 'stream'
_ = require 'lodash'

NodeAssembler = require('../../src/models/node-assembler')
EngineOutputNode = require('../../src/models/engine-output-node')

getVatNodeAssembler = (outputStream) ->
  class VatNodeAssembler extends NodeAssembler
    assembleNodes: =>
      nodes = _.mapValues super, getVatNode
      nodes['engine-output'] = nodes['nanocyte-component-pass-through']

      # nodes = _.mapValues nodes, => nodes['nanocyte-component-pass-through']
      nodes

  getVatNode = (EngineNode, nanocyteType)->
    class VatNode extends EngineNode
      message: (envelope, enc, next) =>
        envelope.metadata.nanocyteType = nanocyteType
        outputStream.write envelope
        super

  VatNodeAssembler

module.exports = getVatNodeAssembler
