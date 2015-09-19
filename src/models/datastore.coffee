class Datastore
  constructor: (dependencies={})->
    {@client} = dependencies
    @client ?= require '../handlers/redis-handler'

  get: (key, callback=->) =>
    @client.get key, (error, data) =>
      callback error, JSON.parse data

module.exports = Datastore
