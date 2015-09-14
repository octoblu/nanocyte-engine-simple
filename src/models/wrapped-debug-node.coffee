module.exports =
  onMessage: (envelope, callback=->) =>
    debugNode = require './unwrapped-debug-node-to-be-replaced'
    debugNode.onMessage envelope, callback
