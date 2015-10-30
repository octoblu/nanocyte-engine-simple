{Transform} = require 'stream'
_ = require 'lodash'
debug = require('debug')('engine-in-a-vat:node-assembler')

NodeAssembler = require('../../src/models/node-assembler')

getVatNodeAssembler = (outputStream) ->
  class VatNodeAssembler extends NodeAssembler
    assembleNodes: =>
      nodes = _.mapValues super, getVatNode
      nodes['engine-output'] = nodes['nanocyte-component-pass-through']
      # nodes['engine-debug'] = nodes['nanocyte-component-pass-through']
      # nodes['engine-data'] = nodes['nanocyte-component-pass-through']
      # nodes['engine-pulse'] = nodes['nanocyte-component-pass-through']

      # nodes = _.mapValues nodes, => nodes['nanocyte-component-pass-through']
      nodes

  getVatNode = (RealNode, nanocyteType)->
    class VatNode extends RealNode
      constructor: ->
        super
      _getEnvelopeStream: (envelope) =>
        envelope.metadata.nanocyteType = nanocyteType
        outputStream.write envelope if envelope? and !outputStream.ended
        super

  VatNodeAssembler

module.exports = getVatNodeAssembler
