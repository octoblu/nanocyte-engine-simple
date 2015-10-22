_ = require 'lodash'
LockManager = require '../../src/models/lock-manager'

describe 'LockManager', ->
  beforeEach ->
    @redlock = lock: sinon.stub(), unlock: sinon.spy()
    @sut = new LockManager {}, redlock: @redlock, client: true
    @sut._generateTransactionId = sinon.stub()

  it 'should exist', ->
    expect(@sut).to.exist

  describe '-> lock', ->
    describe 'when called without a transactionGroupId', ->
      beforeEach (done) ->
        @sut.lock null, null, (@error) => done()

      it 'should yield an error', ->
        expect(@error).to.exist

    describe 'when locking a node', ->
      beforeEach ->
        @sut.lock 'some-node-uuid', null, (@error, @transactionId) =>

      it 'call redlock.lock', ->
        expect(@redlock.lock).to.have.been.calledWith 'locks:some-node-uuid', 6000

      describe 'when successful', ->
        beforeEach ->
          @sut._generateTransactionId.returns 'a-transaction-id'
          @redlock.lock.yield null, 'a-lock'

        it 'should yield a transactionId', ->
          expect(@transactionId).to.deep.equal 'a-transaction-id'

    describe 'when locking a node twice with the same transactionId', ->
      beforeEach (done) ->
        @sut._generateTransactionId.returns 'the-transaction-id'
        @sut.lock 'some-node-uuid', null, (@error, @transactionId) =>
          @sut.lock 'some-node-uuid', @transactionId, (@error) =>
            done()

        @redlock.lock.yield null, 'a-lock'

      it 'should call redlock.lock one time', ->
        expect(@redlock.lock).to.have.been.calledOnce

    describe 'when locking a node twice with a different transactionId', ->
      beforeEach (done) ->
        @theLock = unlock: sinon.spy()
        @sut._generateTransactionId.returns 'the-transaction-id'
        @redlock.lock.yields null, @theLock
        @sut.lock 'some-node-uuid', 'the-transaction-id', (@error, @transactionId) =>
          done()

      describe 'when trying to lock a different transaction', ->
        beforeEach ->
          @lockSuccessful = sinon.spy()
          @redlock.lock.yields new Error 'already locked'
          @sut.lock 'some-node-uuid', 'another-transaction-id', @lockSuccessful

        it 'should call redlock.lock', ->
          expect(@redlock.lock).to.have.been.calledWith "locks:some-node-uuid", 6000

        it 'should not call the callback on the second lock', ->
          expect(@lockSuccessful).to.not.have.been.called

      describe 'when trying to lock a different transaction, and the first transaction is unlocked', ->
        beforeEach ->
          @lockSuccessful = sinon.spy()
          @sut.unlock 'some-node-uuid'
          @redlock.lock.yields null, 'a-new-lock'
          @sut.lock 'some-node-uuid', 'another-transaction-id', @lockSuccessful

        it 'should call redlock.lock', ->
          expect(@redlock.lock).to.have.been.calledWith "locks:some-node-uuid", 6000

        it 'should call the callback on the second lock', ->
          expect(@lockSuccessful).to.have.been.called

  describe '-> unlock', ->
    describe 'when a node is locked', ->
      beforeEach (done) ->
        @theLock = unlock: sinon.stub()
        @redlock.lock.yields null, @theLock
        @sut.lock 'some-node-uuid', null, done

      describe 'when unlocking right away', ->
        beforeEach ->
          @sut.unlock 'some-node-uuid'

        it 'call redlock.unlock', ->
          expect(@theLock.unlock).to.have.been.called

        describe 'when successful', ->
          it 'should remove the lock from @redlock.activeLocks', ->
            expect(_.keys @sut.activeLocks).to.be.empty
            expect(@sut.activeLocks['some-node-uuid']).to.be.undefined

    describe 'when a node is locked twice', ->
      beforeEach (done) ->
        @theLock = unlock: sinon.stub()
        @redlock.lock.yields null, @theLock
        @sut.lock 'some-node-uuid', null, (error, transactionId) =>
          @sut.lock 'some-node-uuid', transactionId, =>
            done()

      describe 'when unlocking once right away', ->
        beforeEach ->
          @sut.unlock 'some-node-uuid'

        it 'does not call redlock.unlock', ->
          expect(@theLock.unlock).to.not.have.been.called

        describe 'when unlocking again', ->
          beforeEach ->
            @sut.unlock 'some-node-uuid'

          it 'should call redlock.unlock', ->
            expect(@theLock.unlock).to.have.been.called
