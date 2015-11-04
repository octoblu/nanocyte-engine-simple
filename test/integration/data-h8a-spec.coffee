_ = require 'lodash'
debug = require('debug')('data-h8a')
Benchmark = require 'simple-benchmark'
EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
describe 'EqualsFigure8', ->
  @timeout 18000
  describe 'when instantiated with a flow', ->

    describe 'When instantiated with a flow', ->
      before (done)->
        flow = require './flows/data-h8a.json'
        @sut = new EngineInAVat flowName: 'data-h8', flowData: flow
        @sut.initialize done

      before (done) ->
        benchmark = new Benchmark label: 'data-h8a'
        intervalId = '9816b370-8313-11e5-8000-3d91638718c3'
        @elapsed = null

        responseStream = @sut.messageRouter intervalId, hello: 'world'
        responseStream.on 'data', (msg) =>
          @elapsed = benchmark.elapsed()
          done()

        responseStream.on 'finish', =>
          debug benchmark.toString()
          done()

      it "Should finish in a reasonable amount of time", ->
        expect(@elapsed).to.be.at.most 800
