Datastore = require './datastore'

class DatastoreWrapper
  constructor: (options={}, dependencies={}) ->
    {@classToWrap} = options
    {@datastore} = dependencies
    @datastore ?= new Datastore

  onMessage: (envelope, callback) =>
    unless @classToWrap?
      error = new Error 'classToWrap is not defined'
      console.error error.stack
      return

    @datastore.get "#{envelope.flowId}/#{envelope.nodeId}/config", (error, config) =>
      if error?
        console.error "ERROR: DatastoreWrapper->onMessage"
        console.error error.stack
        return

      node = new @classToWrap(config)
      node.onMessage envelope.message, callback

module.exports = DatastoreWrapper
