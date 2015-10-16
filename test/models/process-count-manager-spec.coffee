ProcessCountManager = require '../../src/models/process-count-manager'
_                   = require 'lodash'

describe 'ProcessCountManager', ->

  describe '->up', ->
    describe 'when called', ->
      beforeEach ->
        @sut = new ProcessCountManager
        @sut.up()

      it 'should initiate count to 1', ->
        expect(@sut._transactions).to.equal 1

    describe 'when called and count ends at 5', ->
      beforeEach ->
        @sut = new ProcessCountManager
        _.times 5, @sut.up

      it 'should have a count of 5', ->
        expect(@sut._transactions).to.equal 5

  describe '->down', ->
    describe 'when called', ->
      beforeEach ->
        @sut = new ProcessCountManager
        @sut._transactions = 1
        @sut.down()

      it 'should initiate count to 0', ->
        expect(@sut._transactions).to.equal 0

    describe 'when called and count ends at 5', ->
      beforeEach ->
        @sut = new ProcessCountManager
        @sut._transactions = 10
        _.times 5, @sut.down

      it 'should have a count of 5', ->
        expect(@sut._transactions).to.equal 5

  describe '->reset', ->
    describe 'when called with', ->
      beforeEach ->
        @sut = new ProcessCountManager
        @sut.reset()

      it 'should reset the count to zero', ->
        expect(@sut._transactions).to.equal 0

    describe 'when called with a transactionId and count is 5', ->
      beforeEach ->
        @sut = new ProcessCountManager
        @sut._transactions = 5
        @sut.reset()

      it 'should reset the count to 0', ->
        expect(@sut._transactions).to.equal 0

  describe '->checkZero', ->
    describe 'when called and count is not zero', ->
      beforeEach (done) ->
        @callback = sinon.spy()
        @sut = new ProcessCountManager @callback
        @sut._transactions = 5
        @sut.checkZero done

      it 'should not the callback', ->
        expect(@callback).to.not.have.been.called

    describe 'when called and count is zero', ->
      beforeEach (done) ->
        @callback = sinon.spy()
        @sut = new ProcessCountManager @callback
        @sut._transactions = 0
        @sut.checkZero done

      it 'should the callback', ->
        expect(@callback).to.have.been.called
