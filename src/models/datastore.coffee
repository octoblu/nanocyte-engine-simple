_ = require 'lodash'
json3 = require 'json3'
Benchmark = require './benchmark'
debug = require('debug')('nanocyte-engine-simple:datastore')

class Datastore
  constructor: (options, dependencies={})->
    {@client} = dependencies

    @client ?= require '../handlers/redis-handler'

  exists: (key, callback) =>
    @client.exists key, callback

  hget: (key, field, callback) =>
    debug 'hget', key, field
    benchmark = new Benchmark label: 'datastore.hget'
    @client.hget key, field, (error, data) =>
      debug benchmark.toString()
      callback error, json3.parse data

  hset: (key, field, value, callback) =>
    debug 'hset', key, field
    benchmark = new Benchmark label: 'datastore.hset'
    valueStr = JSON.stringify(value)
    if valueStr.length >= 1024 * 1024 * 10
      messageTooLargeError = new Error('Message was too large')
      valueStr = JSON.stringify null
    @client.hset key, field, valueStr, (error) =>
      debug benchmark.toString()
      callback error ? messageTooLargeError

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
