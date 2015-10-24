_ = require 'lodash'
NodeUuid = require 'node-uuid'
Redlock = require 'redlock'
debug = require('debug')('nanocyte-engine-simple:lock-manager')

class LockManager
  constructor: (options, dependencies={}) ->
    {@redlock, @client} = dependencies
    @client ?= require '../handlers/redis-handler'
    @redlock ?= new Redlock [@client]
    @activeLocks = {}

  lock: (transactionGroupId, transactionId, callback) =>
    debug 'lock', transactionGroupId
    return callback() unless transactionGroupId?
    if @activeLocks[transactionGroupId]? && @activeLocks[transactionGroupId].transactionId == transactionId
      @activeLocks[transactionGroupId].count += 1
      return callback()

    @_waitForLock transactionGroupId, transactionId, (error, lock) =>
      transactionId = @_generateTransactionId()
      @activeLocks[transactionGroupId] =
        lockObject: lock
        transactionId: transactionId
        count: 1
      callback error, transactionId

  unlock: (transactionGroupId) =>
    return unless transactionGroupId?
    @activeLocks[transactionGroupId]?.count -= 1
    debug "unlocking: #{transactionGroupId}. #{@activeLocks[transactionGroupId]?.count} locks remaining"
    return if @activeLocks[transactionGroupId].count != 0

    @activeLocks[transactionGroupId]?.lockObject?.unlock()
    delete @activeLocks[transactionGroupId]

  _waitForLock: (transactionGroupId, transactionId, callback) =>
    @redlock.lock "locks:#{transactionGroupId}", 6000, (error, lock) =>
      debug 'waitForLock end', transactionGroupId
      if error?
        debug "error locking #{transactionGroupId}:", error
        _.delay @_waitForLock, 50, transactionGroupId, transactionId, callback
        return
      callback null, lock

  _generateTransactionId: =>
    NodeUuid.v4()

module.exports  = LockManager
