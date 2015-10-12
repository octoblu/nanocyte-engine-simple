Redlock = require 'redlock'
debug = require('debug')('nanocyte-engine-simple:lock-manager')

class LockManager
  constructor: (options, dependencies={}) ->
    {@redlock, @client} = dependencies
    @client ?= require '../handlers/redis-handler'
    @redlock ?= new Redlock [@client]
    @activeLocks = {}

  lock: (resource, callback) =>
    @redlock.lock resource, 6000, (error, lock) =>
      debug 'lock', resource, error
      @activeLocks[resource] = lock unless error?
      callback error

  unlock: (resource) =>
    debug 'unlock', resource
    @activeLocks[resource]?.unlock()
    delete @activeLocks[resource]

module.exports  = LockManager
