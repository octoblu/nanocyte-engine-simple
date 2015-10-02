Benchmark = require './benchmark'
debug = require('debug')('nanocyte-engine-simple:datastore')

class Datastore
  constructor: (dependencies={})->
    {@client} = dependencies
    @client ?= require '../handlers/redis-handler'

  hget: (key, field, callback) =>
    benchmark = new Benchmark label: 'datastore.hget'
    @client.hget key, field, (error, data) =>
      debug benchmark.toString()
      callback error, JSON.parse data

  hset: (key, field, value, callback) =>
    benchmark = new Benchmark label: 'datastore.hset'
    @client.hset key, field, JSON.stringify(value), (error) =>
      debug benchmark.toString()
      callback error

module.exports = Datastore
