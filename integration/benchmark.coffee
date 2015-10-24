_         = require 'lodash'
glob      = require 'glob'
async     = require 'async'
Benchmark = require 'simple-benchmark'
colors    = require 'colors'
debug     = require('debug')('nanocyte-engine-simple:benchmark')

# This avoids the first request performance hit
Router = require '../src/models/router'
new Router

class BenchmarkRunner
  constructor: ->
    @benchmarkRunnerBenchmark = new Benchmark
    @tests = []

  runCount: ({count, @maxAllowedTime}, callback=->) =>
    console.log colors.cyan "** Running #{count} sets **"
    async.timesSeries count, @run, (error) =>
      return callback error if error?
      console.log colors.cyan '** Done with tests **'
      @printBenchMarks()
      callback()

  run: (count=0, done=->) =>
    count++
    forSet = colors.cyan "set #{count}"
    console.log "#{colors.cyan(":>")} running tests for #{forSet}"
    glob "#{__dirname}/units/**/*.coffee", (error, files)=>
      return console.error error if error?
      units = _.map files, (file) =>
        Unit = require file
        unit = new Unit
        return unit

      eachCallback = (unit, done) =>
        forUnit = colors.cyan "#{unit.label}"
        console.log "#{colors.cyan(":>")} starting test for #{forUnit}"
        unit.before (error) =>
          debug 'finished before'
          return done error if error?
          debug 'about to run'
          benchmark = new Benchmark label: unit.label
          unit.run (error, messages) =>
            testResults = elapsed: benchmark.elapsed(), set: count, label: unit.label
            @tests.push testResults
            timeTook = colors.green "#{testResults.elapsed}ms"
            debug 'ran test'
            console.log "#{colors.cyan(":>")} finished test for #{forUnit} #{timeTook}"
            if messages?
              console.log "Message trace:"
              @printMessageTrace messages
            return done error if error?
            unit.after (error) =>
              debug 'finished after'
              return done error if error?
              done()

      endEachCallback = (error) =>
        return done error if error?
        console.log "#{colors.cyan(":>")} finished tests for #{forSet}"
        done null, {set: count}

      async.eachSeries units, eachCallback, endEachCallback

  printAllTests: (tests) =>
    testsByLabel = {}
    _.each @tests, (test) =>
      testsByLabel[test.label] ?= {}
      testsByLabel[test.label].totalMs ?= 0
      testsByLabel[test.label].totalMs += test.elapsed
      testsByLabel[test.label].times ?= []
      testsByLabel[test.label].times.push test.elapsed
      testsByLabel[test.label].count ?= 0
      testsByLabel[test.label].count++

    _.each _.keys(testsByLabel), (label) =>
      {totalMs, count, times} = testsByLabel[label]
      totalMsWithMs = "#{totalMs}ms"
      console.log ''
      console.log colors.cyan ">>>>> #{label} Results <<<<<"
      console.log "Total Time: #{colors.green totalMsWithMs}"
      console.log "Total Count: #{colors.green count}"
      median = @nthPercentile 50, times
      percentile90 = @nthPercentile 90, times
      console.log "Median: #{colors.green median}"
      console.log "90th Percentile: #{colors.green percentile90}"
      averageTime = totalMs / count
      averageTimeWithMs = "#{averageTime}ms"
      console.log "Average Time: #{colors.green averageTimeWithMs}"
      if median > @maxAllowedTime
        console.log colors.red 'maxAllowedTime exceeded, exiting with error'
        process.exit 1

  printBenchMarks: (tests) =>
    @printAllTests tests
    console.log ''
    console.log '========================='
    console.log 'Tests Completed!'
    console.log "Tests Ran: #{colors.green @tests.length}"
    totalTime = "#{@benchmarkRunnerBenchmark.elapsed()}ms"
    console.log "Total Time: #{colors.green totalTime}"
    console.log '========================='

  printMessageTrace: (messages) =>
    console.log '\n~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*'
    lastTime = null
    _.each messages, (message) =>
      elapsed = message.timestamp - lastTime if lastTime?
      console.log "#{@getMessageString message, elapsed}"
      lastTime = message.timestamp
    console.log '~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*'

  getMessageString: (message, elapsed) =>
    timeString = "[first]"
    timeString = "[#{elapsed}ms later]" if elapsed?
    "from #{message.metadata.fromNodeId} #{colors.yellow timeString}"

  nthPercentile: (percentile, array) =>
    array = _.sortBy array
    index = (percentile / 100) * _.size(array)
    if Math.floor(index) == index
      return (array[index-1] + array[index]) / 2
    return array[Math.floor index]

module.exports = BenchmarkRunner
