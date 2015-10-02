_ = require 'lodash'
ErrorStream = require '../../src/models/error-stream'

describe 'ErrorStream', ->
  beforeEach ->
    @sut = new ErrorStream {}

  describe 'when instantiated with an error', ->
    beforeEach ->
      error = new Error('oh no')
      @sut = new ErrorStream error: error

    describe 'when an error is written', ->
      beforeEach (done) ->
        @sut.on 'end', done

        @things = []

        @sut.on 'readable', =>
          while thing = @sut.read()
            @things.push thing

        @sut.write
          flowId:     'flow-uuid'
          instanceId: 'instance-uuid'
          fromNodeId: 'from-node-uuid'
          toNodeId:   'to-node-uuid'
          message:    'something happy'

      it 'should overwrite message, msgType, and fromNodeId, toNodeId', ->
        expect(@things).to.deep.contain
          flowId: 'flow-uuid'
          instanceId: 'instance-uuid'
          fromNodeId: 'to-node-uuid'
          toNodeId:   'engine-debug'
          message: 'oh no'
          msgType: 'error'


  describe 'when instantiated with an error', ->
    beforeEach ->
      error = new Error('No, oh!')
      @sut = new ErrorStream error: error

    describe 'when an error is written', ->
      beforeEach (done) ->
        @sut.on 'end', done

        @things = []

        @sut.on 'readable', =>
          while thing = @sut.read()
            @things.push thing

        @sut.write
          flowId:     'different-flow-uuid'
          instanceId: 'a-new-instance-uuid'
          fromNodeId: 'from-another-node-uuid'
          toNodeId:   'to-yet-another-node-uuid'
          message:    'something not happy'

      it 'should overwrite message, msgType, and fromNodeId, toNodeId', ->
        expect(_.size @things).to.equal 1
        expect(_.first @things).to.deep.equal
          flowId: 'different-flow-uuid'
          instanceId: 'a-new-instance-uuid'
          fromNodeId: 'to-yet-another-node-uuid'
          toNodeId:   'engine-debug'
          message: 'No, oh!'
          msgType: 'error'
