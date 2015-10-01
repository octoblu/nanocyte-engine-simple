class Datastore
  constructor: (dependencies={})->
    {@client} = dependencies
    @client ?= require '../handlers/redis-handler'

  hget: (key, field, callback) =>
    @client.hget key, field, (error, data) =>
      callback error, JSON.parse data

  hset: (key, field, value, callback) =>
    @client.hset key, field, JSON.stringify(value), callback

module.exports = Datastore
