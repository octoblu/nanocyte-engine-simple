class NanocyteNodeWrapper
  constructor: ({nodeClass: @nodeClass}) ->

  onEnvelope: (envelope, callback) =>
    node = new @nodeClass envelope.config, envelope.data
    node.onMessage envelope.message, callback

module.exports = NanocyteNodeWrapper
