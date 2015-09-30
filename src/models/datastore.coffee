class Datastore
  constructor: (dependencies={})->
    {@client} = dependencies
    @client ?= require '../handlers/redis-handler'

  hget: (key, field, callback) =>
    @client.hget key, field, (error, data) =>
      callback error, JSON.parse data

  set: (key, value, callback) =>
    @client.set key, JSON.stringify(value), callback

module.exports = Datastore
