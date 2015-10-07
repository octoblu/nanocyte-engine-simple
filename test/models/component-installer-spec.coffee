ComponentInstaller = require '../../src/models/component-installer'
{PassThrough} = require 'stream'
describe 'ComponentInstaller', ->
  beforeEach ->
    @requestStream = new PassThrough
    @fsStream = new PassThrough
    @npm =
      load: sinon.stub().yields()
      commands:
        install: sinon.stub().yields()

    @request = sinon.stub().returns @requestStream
    @getComponentList = getComponentList = sinon.stub()

    @ComponentLoader = class ComponentLoader
      getComponentList: getComponentList

    @fs =  createWriteStream: sinon.stub().returns @fsStream

    @sut = new ComponentInstaller(
      {registryUrl: 'http://magical.school/friendship'}
      {request: @request, fs: @fs, ComponentLoader: @ComponentLoader, npm: @npm}
    )

  it 'should exist', ->
    expect(@sut).to.exist

  describe '->downloadRegistry', ->
    describe 'when called', ->
      beforeEach (done) ->
        @requestStream.end @registry
        @sut.downloadRegistry => done()

      it 'should get the node registry with request', ->
        expect(@request).to.have.been.calledWith url: "http://magical.school/friendship", json: true

    describe 'when called and the request returns a file', ->
      beforeEach (done) ->
        @registry = JSON.stringify hi: 'bob'
        @fsStream.on 'data', (@file) =>
        @requestStream.end @registry

        @sut.downloadRegistry  (@error) => done()


      it 'should open a file named "nanocyte-node-registry.json"', ->
        expect(@fs.createWriteStream).to.have.been.calledWith './nanocyte-node-registry.json'

      it 'should write the request data into the file stream', ->
        expect(@file.toString()).to.equal @registry

  describe '->installComponents', ->
    describe 'when called', ->
      beforeEach (done) ->
        @getComponentList.returns [ 'mangodb', 'moheeb-generator' ]
        @sut.installComponents null, (@error, @response)=> done()

      it 'should call npm.load', ->
        expect(@npm.load).to.have.been.called

      it 'should call componentLoader.getComponentList', ->
        expect(@getComponentList).to.have.been.called

      it 'should call npm.install for each component returned by the loader', ->
        expect(@npm.commands.install).to.have.been.calledWith ['mangodb', 'moheeb-generator']


    describe 'when called and npm.load yields an error', ->
      beforeEach (done) ->
        @npm.load.yields(new Error('waaaaat'))
        @sut.installComponents null, (@error, @response)=> done()

      it 'should call the callback with the error', ->
        expect(@error).to.exist
