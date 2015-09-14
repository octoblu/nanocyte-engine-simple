redis = require 'redis'

class Datastore
  constructor: (dependencies={})->
    {@client} = dependencies
    @client ?= redis.createClient()

  get: (key, callback=->) =>
    @client.get key, (error, data) =>
      callback error, JSON.parse data

module.exports = Datastore
