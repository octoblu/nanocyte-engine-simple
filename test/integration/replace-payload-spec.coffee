_ = require 'lodash'
debug = require('debug')('equals-train-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
shmock = require 'shmock'
enableDestroy = require 'server-destroy'

describe 'replace payload', ->
  @timeout 10000
  beforeEach (done) ->
    @meshblu = shmock done
    enableDestroy @meshblu
    @searchRequest = @meshblu.post('/search/devices').reply 201, []

  afterEach (done) ->
    @meshblu.destroy done

  beforeEach ->
    @meshbluJSON =
      uuid: 'uuid'
      token: 'token'
      server: 'localhost'
      port: @meshblu.address().port

  beforeEach (done) ->
    flow = require './flows/replace-payload.json'
    @sut = new EngineInAVat flowName: 'metadata-forwarding', flowData: flow, meshbluJSON: @meshbluJSON
    @sut.initialize done

  beforeEach (done) ->
    message =
      replacePayload: "asdf"
      asdf:
        hello: "hi"

    @sut.triggerByName {name: 'Output', message: message}, (error, @messages) => done()

  it "Should send messages", ->
    expect(@messages).to.containSubset [
      {
        message: payload: payload: payload: hello: "hi"
      }
    ]
