_ = require 'lodash'
debug = require('debug')('data-benchmark')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
xdescribe 'DataBenchmark', ->
  @timeout 18000
  describe 'When instantiated with a flow', ->
    before (done)->
      flow = require './flows/data-benchmark.json'
      @sut = new EngineInAVat flowName: 'data-benchmark', flowData: flow
      @sut.initialize done

    before (done) ->
      startTime = Date.now()
      intervalId = '9816b370-8313-11e5-8000-3d91638718c3'
      @sut.messageEngine intervalId, hello: 'world', undefined, (error, @messages) =>
        @totalTime = Date.now() - startTime
        done()

    it "Should finish in a reasonable amount of time", ->
      expect(@totalTime).to.be.at.most 4000

    it "Should finish each message in a reasonable amount of time", ->
      expect(@totalTime/@messages.length).to.be.at.most 60
