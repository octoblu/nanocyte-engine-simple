_ = require 'lodash'
debug = require('debug')('equals-train-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

describe 'metadata-forwarding', ->
  @timeout 60000

  beforeEach (done) ->
    flow = require './flows/metadata-forwarding-flow.json'
    @sut = new EngineInAVat flowName: 'metadata-forwarding', flowData: flow
    @sut.initialize done

  beforeEach (done) ->
    @sut.triggerByName {name: 'Trigger', message: 1}, (error, @messages) => done()

  it "Should send messages", ->
    console.log JSON.stringify @messages, null, 2
    expect(@messages).not.to.exist
