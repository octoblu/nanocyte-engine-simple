MeshbluOutputNode = require './meshblu-output-node'
module.exports = onMessage: (envelope) =>
  meshbluOutputNode = new MeshbluOutputNode
  meshbluOutputNode.onMessage envelope
