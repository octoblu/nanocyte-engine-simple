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

  canLock: (transactionGroupId, transactionId) =>
    return false unless @activeLocks[transactionGroupId]?
    @activeLocks[transactionGroupId].transactionId == transactionId

  lock: (transactionGroupId, transactionId, callback) =>
    return callback() unless transactionGroupId?
    if @canLock transactionGroupId, transactionId
      @activeLocks[transactionGroupId].count += 1

      debug "already locked: #{transactionGroupId}. transactionId: #{transactionId} count: #{@activeLocks[transactionGroupId].count}"
      return callback null, transactionId

    @_acquireLock transactionGroupId, (error, lock) =>
      transactionId = @_generateTransactionId()
      @activeLocks[transactionGroupId] =
        lockObject: lock
        transactionId: transactionId
        count: 1

      debug "locked: #{transactionGroupId}. transactionId: #{transactionId} count: #{@activeLocks[transactionGroupId].count}"
      callback error, transactionId

  unlock: (transactionGroupId) =>
    return unless transactionGroupId?
    return unless @activeLocks[transactionGroupId]?

    @activeLocks[transactionGroupId].count -= 1
    debug "unlocking: #{transactionGroupId}. #{@activeLocks[transactionGroupId]?.count} locks remaining"

    return if @activeLocks[transactionGroupId].count != 0
    @activeLocks[transactionGroupId].lockObject?.unlock()
    delete @activeLocks[transactionGroupId]

    debug "unlocked: #{transactionGroupId}"

  _acquireLock: (transactionGroupId, callback) =>
    debug 'acquireLock', transactionGroupId
    @redlock.lock "locks:#{transactionGroupId}", 6000, (error, lock) =>
      debug 'redlock', error
      callback null, lock

  _generateTransactionId: =>
    NodeUuid.v4()

module.exports = LockManager
