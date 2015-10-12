Benchmark = require './benchmark'
debug = require('debug')('nanocyte-engine-simple:datastore')
_ = require 'lodash'

class Datastore
  constructor: (options, dependencies={})->
    {@client} = dependencies
    @client ?= require '../handlers/redis-handler'

  exists: (key, callback) =>
    @client.exists key, callback

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

  setex: (key, timeout) =>
    @client.setex key, timeout, ''

  getAndIncrementCount: (key, callback) =>
    @client
      .multi()
      .incr   key
      .expire key, 10
      .exec (error, results) =>
        count = _.first results
        callback error, count

module.exports = Datastore
