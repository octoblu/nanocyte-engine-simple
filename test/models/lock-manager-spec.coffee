_ = require 'lodash'
LockManager = require '../../src/models/lock-manager'

describe 'LockManager', ->
  beforeEach ->
    @redlock = lock: sinon.stub()
    @sut = new LockManager {}, redlock: @redlock

  it 'should exist', ->
    expect(@sut).to.exist

  describe '-> lock', ->
    describe 'when locking a node', ->
      beforeEach ->
        @sut.lock 'locks:node:some-node-uuid', (@error) =>

      it 'call redlock.lock', ->
        expect(@redlock.lock).to.have.been.calledWith 'locks:node:some-node-uuid', 6000

      describe 'when successful', ->
        beforeEach ->
          @redlock.lock.yield null, 'a-lock'

        it 'should add the lock to @redlock.activeLocks', ->
          expect(@sut.activeLocks['locks:node:some-node-uuid']).to.deep.equal 'a-lock'

      describe 'when unsuccessful', ->
        beforeEach ->
          @lockError = new Error 'something wrong'
          @redlock.lock.yield @lockError

        it 'should not add the lock to @redlock.activeLocks', ->
          expect(_.keys @sut.activeLocks).to.be.empty
          expect(@sut.activeLocks['locks:node:some-node-uuid']).to.be.undefined

        it 'should callback with an error', ->
          expect(@error).to.deep.equal @lockError

  describe '-> unlock', ->
    describe 'when locking a node', ->
      beforeEach ->
        @theLock = unlock: sinon.stub()
        @redlock.lock.yields null, @theLock
        @sut.lock 'locks:node:some-node-uuid', =>
        @sut.unlock 'locks:node:some-node-uuid'

      it 'call redlock.unlock', ->
        expect(@theLock.unlock).to.have.been.called

      describe 'when successful', ->
        it 'should remove the lock from @redlock.activeLocks', ->
          expect(_.keys @sut.activeLocks).to.be.empty
          expect(@sut.activeLocks['locks:node:some-node-uuid']).to.be.undefined
