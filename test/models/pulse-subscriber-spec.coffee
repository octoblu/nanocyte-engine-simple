PulseSubscriber = require '../../src/models/pulse-subscriber'

describe 'PulseSubscriber', ->
  beforeEach ->
    @datastore = setex: sinon.stub()
    @sut = new PulseSubscriber {}, datastore: @datastore

  describe '-> subscribe', ->
    describe 'with some flow', ->
      beforeEach ->
        @sut.subscribe 'some-flow-uuid'

      it 'should call setex on the datastore with a flow-uuid', ->
        expect(@datastore.setex).to.have.been.calledWith 'some-flow-uuid', 300

    describe 'with some other flow', ->
      beforeEach ->
        @sut.subscribe 'some-other-flow-uuid'

      it 'should call setex on the datastore with a flow-uuid', ->
        expect(@datastore.setex).to.have.been.calledWith 'some-other-flow-uuid', 300
