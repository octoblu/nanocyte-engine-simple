_ = require 'lodash'
NodeUuid = require 'node-uuid'
Redlock = require 'redlock'
debug = require('debug')('nanocyte-engine-simple:lock-manager')

class LockManager
  constructor: (options={}, dependencies={}) ->
    {@redlock, @client, @instanceCount, @messageCounter} = dependencies
    {redlock:redlockOptions} = options
    redlockOptions ?= {}
    redlockOptions.retryCount ?= 60*50
    redlockOptions.retryDelay ?= 20
    @client ?= require '../handlers/redis-handler'
    @redlock ?= new Redlock [@client], redlockOptions
    @activeLocks = {}

  canLock: (transactionGroupId, transactionId) =>
    return false unless @activeLocks[transactionGroupId]?
    @activeLocks[transactionGroupId].transactionId == transactionId

  getInfo: (transactionGroupId, transactionId) =>
    "#{transactionGroupId}- " +
    if transactionId? then "transactionId: #{transactionId}" else "" +
    " count: #{@activeLocks[transactionGroupId]?.count}"

  lock: (transactionGroupId, transactionId, callback) =>
    @messageCounter.add()
    return callback() unless transactionGroupId?

    if @canLock transactionGroupId, transactionId
      @activeLocks[transactionGroupId].count += 1
      debug "#{@instanceCount} already locked: ", @getInfo transactionGroupId, transactionId
      return callback null, transactionId

    @_acquireLock transactionGroupId, (error, lock) =>
      return callback(error or new Error 'unspecified redlock error') if error? or !lock?
      transactionId = @_generateTransactionId()
      @activeLocks[transactionGroupId] =
        lockObject: lock
        transactionId: transactionId
        count: 1

      debug "#{@instanceCount} locked: ", @getInfo transactionGroupId, transactionId
      callback error, transactionId

  unlock: (transactionGroupId) =>
    @messageCounter.subtract()
    return unless transactionGroupId?
    return unless @activeLocks[transactionGroupId]?

    @activeLocks[transactionGroupId].count -= 1
    debug "#{@instanceCount} unlocking: ", @getInfo transactionGroupId

    return if @activeLocks[transactionGroupId].count != 0
    @activeLocks[transactionGroupId].lockObject?.unlock()

    delete @activeLocks[transactionGroupId]

    debug "#{@instanceCount} unlocked: ", @getInfo transactionGroupId

  _acquireLock: (transactionGroupId, callback) =>
    debug "#{@instanceCount} acquireLock", transactionGroupId
    @redlock.lock "locks:#{transactionGroupId}", 60*1000, (error, lock) =>
      debug "#{@instanceCount} redlock #{lock}", error
      return setImmediate @_acquireLock, transactionGroupId, callback if error? or !lock?
      callback error, lock

  _generateTransactionId: =>
    NodeUuid.v4()

module.exports = LockManager
