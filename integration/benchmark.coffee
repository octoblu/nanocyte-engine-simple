_         = require 'lodash'
glob      = require 'glob'
async     = require 'async'
Benchmark = require 'simple-benchmark'
colors    = require 'colors'
debug     = require('debug')('nanocyte-engine-simple:benchmark')

class BenchmarkRunner
  constructor: ->
    @benchmarkRunnerBenchmark = new Benchmark
    @tests = []

  runCount: (timesToRun=1, callback=->) =>
    console.log colors.cyan "** Running #{timesToRun} sets **"
    async.timesSeries parseInt(timesToRun), @run, (error) =>
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
        benchmark = new Benchmark label: unit.label
        unit.before (error) =>
          debug 'finished before'
          return done error if error?
          debug 'about to run'
          unit.run (error) =>
            debug 'ran test'
            return done error if error?
            unit.after (error) =>
              debug 'finished after'
              testResults = elapsed: benchmark.elapsed(), set: count, label: unit.label
              @tests.push testResults
              timeTook = colors.green "#{testResults.elapsed}ms"
              console.log "#{colors.cyan(":>")} finished test for #{forUnit} #{timeTook}"
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
      testsByLabel[test.label].count ?= 0
      testsByLabel[test.label].count++

    _.each _.keys(testsByLabel), (label) =>
      {totalMs, count} = testsByLabel[label]
      totalMsWithMs = "#{totalMs}ms"
      console.log ''
      console.log colors.cyan ">>>>> #{label} Results <<<<<"
      console.log "Total Time: #{colors.green totalMsWithMs}"
      console.log "Total Count: #{colors.green count}"
      averageTime = totalMs / count
      averageTimeWithMs = averageTime
      console.log "Average Time: #{colors.green averageTimeWithMs}"

  printBenchMarks: (tests) =>
    @printAllTests tests
    console.log ''
    console.log '========================='
    console.log 'Tests Completed!'
    console.log "Tests Ran: #{colors.green @tests.length}"
    totalTime = "#{@benchmarkRunnerBenchmark.elapsed()}ms"
    console.log "Total Time: #{colors.green totalTime}"
    console.log '========================='

module.exports = BenchmarkRunner
