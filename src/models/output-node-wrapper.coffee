class OutputNodeWrapper
  constructor: ({nodeClass: @nodeClass}) ->

  onEnvelope: (envelope) =>
    node = new @nodeClass
    node.onMessage envelope

module.exports = OutputNodeWrapper
