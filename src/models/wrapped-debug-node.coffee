DatastoreWrapper = require './datastore-wrapper'

module.exports =
  onMessage: (envelope, callback=->) =>
    DebugNode = require './unwrapped-debug-node-to-be-replaced'

    wrappedDebugNode = new DatastoreWrapper classToWrap: DebugNode
    wrappedDebugNode.onMessage envelope, callback
