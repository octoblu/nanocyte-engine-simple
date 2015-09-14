Datastore = require '../models/datastore'

module.exports =
  get: (key, callback=->) ->
    datastore = new Datastore
    datastore.get key, callback
