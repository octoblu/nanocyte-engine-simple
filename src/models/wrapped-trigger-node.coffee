DatastoreWrapper = require './datastore-wrapper'

module.exports =
  onMessage: (envelope, callback) =>
    TriggerNode = require 'nanocyte-node-trigger'

    wrappedTriggerNode = new DatastoreWrapper classToWrap: TriggerNode
    wrappedTriggerNode.onMessage envelope, callback
