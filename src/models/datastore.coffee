redis = require 'redis'

class Datastore
  constructor: (dependencies={})->
    {@client} = dependencies
    @client ?= redis.createClient process.env.REDIS_PORT, process.env.REDIS_HOST, auth_pass: process.env.REDIS_PASSWORD

  get: (key, callback=->) =>
    @client.get key, (error, data) =>
      callback error, JSON.parse data

module.exports = Datastore
