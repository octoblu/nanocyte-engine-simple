_ = require 'lodash'
NodeUuid = require 'node-uuid'
Redlock = require 'redlock'
debug = require('debug')('nanocyte-engine-simple:lock-manager')

class LockManager
  constructor: (options, dependencies={}) ->
    @messagesInProgress = 0
    {@redlock, @client} = dependencies
    @client ?= require '../handlers/redis-handler'
    @redlock ?= new Redlock [@client]
    @activeLocks = {}

  lock: (transactionGroupId, transactionId, callback) =>
    @messagesInProgress++
    console.log "[#{Date.now()}] <#{transactionGroupId}> lock: messages in progress: #{@messagesInProgress}"
    return callback new Error('Missing transactionGroupId') unless transactionGroupId?
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
    @messagesInProgress--
    console.log "[#{Date.now()}] <#{transactionGroupId}> unlock: messages in progress: #{@messagesInProgress}"

    return unless transactionGroupId?
    debug 'unlock', transactionGroupId
    @activeLocks[transactionGroupId]?.count -= 1
    return if @activeLocks[transactionGroupId].count != 0

    @activeLocks[transactionGroupId]?.lockObject?.unlock()
    delete @activeLocks[transactionGroupId]

  _waitForLock: (transactionGroupId, transactionId, callback) =>
    @redlock.lock "locks:#{transactionGroupId}", 6000, (error, lock) =>
      debug 'lock', transactionGroupId
      if error?
        _.delay @_waitForLock, 50, transactionGroupId, transactionId, callback
        return
      callback null, lock

  _generateTransactionId: =>
    NodeUuid.v4()

module.exports  = LockManager
