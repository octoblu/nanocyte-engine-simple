_ = require 'lodash'
json3 = require 'json3'
Benchmark = require './benchmark'
debug = require('debug')('nanocyte-engine-simple:datastore')
# testDebug = require('debug')('nanocyte-test')

class Datastore
  constructor: (options, dependencies={})->
    {@client} = dependencies
    # unless @client?
    #   throw new Error 'Constructing a REAL data store!!!'

    @client ?= require '../handlers/redis-handler'

  exists: (key, callback) =>
    @client.exists key, callback

  hget: (key, field, callback) =>
    benchmark = new Benchmark label: 'datastore.hget'
    @client.hget key, field, (error, data) =>
      debug benchmark.toString()
      callback error, json3.parse data

  hset: (key, field, value, callback) =>
    benchmark = new Benchmark label: 'datastore.hset'
    @client.hset key, field, JSON.stringify(value), (error) =>
      debug benchmark.toString()
      callback error

  setex: (key, timeout, value, callback) =>
    @client.setex key, timeout, value, callback

  getAndIncrementCount: (key, callback) =>
    @client
      .multi()
      .incr   key
      .expire key, 10
      .exec (error, results) =>
        count = _.first results
        callback error, count

module.exports = Datastore
