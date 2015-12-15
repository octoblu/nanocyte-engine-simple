_ = require 'lodash'
colors = require 'colors'
debug = require('debug')('engine-in-a-vat:message-util')
{Stats} = require 'fast-stats'

class MessageUtil

  @getStats: (startTime, messages) ->
    previousTime = startTime

    messageTimes = _.map messages, (message) =>
      thisTime = Date.now()
      elapsed  = thisTime - previousTime
      previousTime = thisTime
      return elapsed

    stats = new Stats()
    stats.push messageTimes
    mean = _.round stats.amean(), 2
    errorMargin = _.round stats.moe(), 2

    messageStats =
      mean:
        actualMean: mean
        errorMargin: errorMargin
        upperLimit95: mean + errorMargin
        lowerLimit95: mean - errorMargin

      median: stats.median()
      total: _.sum messageTimes
      range:
        from: stats.range()[0]
        to: stats.range()[1]

    return messageStats

  @print: (envelope) ->
    {metadata, message} = envelope
    debugInfo = metadata.debugInfo || {}

    # messageString = "unparsed-message"
    #messageString = JSON.stringify envelope, null, 2
    messageString = envelope?.message?.payload?.msg
    lastTime = debugInfo.timestamp unless lastTime?
    timeDiff = debugInfo.timestamp - lastTime
    lastTime = debugInfo.timestamp


    # "[#{colors.yellow metadata.transactionId}] " +
    # "#{debugInfo.fromNodeName || metadata.fromNodeId} #{colors.gray debugInfo.fromNodeType} : " +
    # "--> " +
    # "#{debugInfo.toNodeName || metadata.toNodeId} #{colors.green debugInfo.nanocyteType} (#{debugInfo.toNodeType})\n" +
    " #{colors.green messageString}" if messageString

  @printStats: (messages) =>
    debug "\nINCOMING:"
    @printIncoming messages
    debug "\nOUTGOING:"
    @getOutgoing messages

  @printIncoming: (messages) =>
    messagesByType = _.groupBy messages, (envelope) =>
      return envelope.metadata.debugInfo.toNode?.config.name || envelope.metadata.toNodeId
    _.each messagesByType, (messages, type) =>
      debug "#{type} got #{messages.length} messages"

  @getOutgoing: (messages) =>
    #console.log JSON.stringify messages, null, 2
    process.exit -1
    messagesByType = _.groupBy messages, (envelope) =>
      return envelope.metadata.debugInfo.fromNode?.config.name || envelope.metadata.fromNodeId

    _.each messagesByType, (messages, type) =>
      return unless type?

      nodeNames = _.compact _.map messages, (envelope) =>
        return envelope.metadata.debugInfo.toNode?.config.name || envelope.metadata.toNodeId

      debug "#{type} sent #{messages.length} messages to", nodeNames

      return nodeNames

module.exports = MessageUtil
