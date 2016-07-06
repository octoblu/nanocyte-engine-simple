_ = require 'lodash'
Benchmark = require './benchmark'
debug = require('debug')('nanocyte-engine-simple:datastore')

class Datastore
  constructor: (options, dependencies={})->
    {@client} = dependencies

    @client ?= require '../handlers/redis-handler'

  exists: (key, callback) =>
    @client.exists key, callback

  hget: (key, field, callback) =>
    benchmark = new Benchmark label: 'datastore.hget'
    debug 'hget', key, field
    @client.hget key, field, (error, data) =>
      debug benchmark.toString()
      return callback error if error?
      return callback null, data unless data?
      try
        parsedData = JSON.parse data
      catch error
        return callback error if error?
      callback null, parsedData

  hmget: (key, fields, callback) =>
    benchmark = new Benchmark label: 'datastore.hmget'
    debug 'hmget', key, fields
    @client.hmget key, fields, (error, results) =>
      debug benchmark.toString()
      return callback error if error?
      parsedData = _.map results, (data) =>
        return data unless data?
        try
          JSON.parse data
        catch error
      callback null, parsedData

  get: (key, callback) =>
    benchmark = new Benchmark label: 'datastore.get'
    @client.get key, (error, data) =>
      debug benchmark.toString()
      return callback error if error?
      return callback null, data unless data?
      try
        parsedData = JSON.parse data
      catch error
        return callback error if error?
      callback null, parsedData

  hset: (key, field, value, callback) =>
    benchmark = new Benchmark label: 'datastore.hset'
    valueStr = JSON.stringify(value)
    if valueStr.length >= 1024 * 512
      messageTooLargeError = new Error('Message was too large')
      valueStr = JSON.stringify null
    @client.hset key, field, valueStr, (error) =>
      debug benchmark.toString()
      callback error ? messageTooLargeError

  setex: (key, timeout, value, callback) =>
    @client.setex key, timeout, value, callback

  getAndIncrementCount: (key, increment, expirationTime, callback) =>
    @client.expire key, expirationTime, (error) =>
      return callback error if error?
      @client.incrby key, increment, callback

module.exports = Datastore
