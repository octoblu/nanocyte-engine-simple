class NanocyteNodeWrapper
  constructor: ({nodeClass: @nodeClass}) ->

  onEnvelope: (envelope, callback) =>
    node = new @nodeClass envelope.config, envelope.data
    node.onMessage envelope.message, (error, message) =>
      callback error,
        fromNodeId: envelope.toNodeId
        flowId:     envelope.flowId
        message:    message


module.exports = NanocyteNodeWrapper
