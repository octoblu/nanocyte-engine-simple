DatastoreWrapper = require '../../src/models/datastore-wrapper'

describe 'DatastoreWrapper', ->
  it 'should be', ->
    @sut = new DatastoreWrapper
    expect(@sut).to.exist

  describe '->onMessage', ->
    beforeEach ->
      @nodeOnMessage = sinon.spy()

      SomeClass = =>
        onMessage: @nodeOnMessage

      @someClass = sinon.spy SomeClass
      @datastore = get: sinon.stub()

      @sut = new DatastoreWrapper {classToWrap: @someClass}, {datastore: @datastore}
      @sut.onMessage
        flowId: 'flow-uuid'
        nodeId: 'node-uuid'
        message: {more: 'of the things', i: 'want'}

    describe 'on successful request', ->
      beforeEach ->
        @datastore.get.yield null, anything: 'i want'

      it 'should call get on the datastore', ->
        expect(@datastore.get).to.have.been.calledWith 'flow-uuid/node-uuid/config'

      it 'should instantiate the node with the datastore config', ->
        expect(@someClass).to.have.been.calledWithNew
        expect(@someClass).to.have.been.calledWith anything: 'i want'

      it 'should call the wrapped node onMessage', ->
        expect(@nodeOnMessage).to.have.been.calledWith {more: 'of the things', i: 'want'}

    describe 'when classToWrap is null', ->
      beforeEach ->
        @consoleError = sinon.stub console, 'error'
        @error = new Error 'classToWrap is not defined'
        @datastore.get.yield @error

      afterEach ->
        @consoleError.restore()

      it 'should call console.error with the errors stack', ->
        expect(@consoleError).to.have.been.calledWith @error.stack
