DatastoreInStream = require '../../src/models/datastore-get-stream'

describe 'DatastoreInStream', ->
  describe '->onEnvelope', ->
    beforeEach ->
      @datastore = get: sinon.stub()
      @sut = new DatastoreInStream {}, datastore: @datastore

    describe 'when datastore returns some data', ->
      beforeEach ->
        @datastore.get.withArgs('flow-uuid/node-uuid/config').yields null, {foo: 'bar'}
        @datastore.get.withArgs('flow-uuid/node-uuid/data').yields null, {is: 'data'}

      describe 'when called with an envelope', ->
        beforeEach (done) ->
          envelope =
            flowId:     'flow-uuid'
            toNodeId: 'node-uuid'
            message:    {dont: 'lose me'}
          @sut.onEnvelope envelope, (@error, @result) => done()

        it 'should call the callback with a mutated envelope', ->
          expect(@result).to.deep.equal
            flowId: 'flow-uuid'
            toNodeId: 'node-uuid'
            message: {dont: 'lose me'}
            config:  {foo: 'bar'}
            data:    {is: 'data'}

    describe 'when datastore returns some different data', ->
      beforeEach ->
        @datastore.get.withArgs('the-flow-uuid/the-node-uuid/config').yields null, {coffee: 'cup'}
        @datastore.get.withArgs('the-flow-uuid/the-node-uuid/data').yields null, {water: 'bottle'}

      describe 'when called with an different envelope', ->
        beforeEach (done) ->
          envelope =
            flowId:     'the-flow-uuid'
            toNodeId: 'the-node-uuid'
            message:    {do: 'lose me now'}
          @sut.onEnvelope envelope, (@error, @result) => done()

        it 'should call the callback with a mutated envelope', ->
          expect(@result).to.deep.equal
            flowId: 'the-flow-uuid'
            toNodeId: 'the-node-uuid'
            message: {do: 'lose me now'}
            config:  {coffee: 'cup'}
            data:    {water:  'bottle'}
