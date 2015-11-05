_ = require 'lodash'
debug = require('debug')('data-benchmark')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
describe 'DataBenchmark', ->
  @timeout 18000
  describe 'When instantiated with a flow', ->
    beforeEach (done)->
      flow = require './flows/data-benchmark.json'
      @sut = new EngineInAVat flowName: 'data-benchmark', flowData: flow
      @sut.initialize done

    beforeEach (done) ->
      intervalId = '9816b370-8313-11e5-8000-3d91638718c3'
      @sut.messageRouter intervalId, hello: 'world', (error, @stats) => done()

    it "Should finish in a reasonable amount of time", ->
      expect(@stats.total).to.be.at.most 2000

    it "Should finish each message in a reasonable amount of time", ->
      expect(@stats.mean.upperLimit95).to.be.at.most 30
