ChristacheioStream = require '../../src/models/christacheio-stream'

describe 'ChristacheioStream', ->

  describe 'when constructed', ->
    beforeEach ->
      @sut = new ChristacheioStream

    describe 'when a nanocyte envelope with templating is written to it', ->
      beforeEach (done) ->
        @sut.write config: {foo: "{{bar}}"}, data: {}, message: {bar: 'duck'}

        @sut.on 'data', (@result) => done()

      it 'should template the config in the envelope', ->
        expect(@result).to.deep.equal
          config: {foo: 'duck'}
          data: {}
          message: {bar: 'duck'}

    describe 'I think this is why we double pass', ->
      beforeEach (done) ->
        envelope =
          config: {duckGoes: "{{bar}}"}
          data: {}
          message: {bar: '{{sound}}', sound: 'quack'}

        @sut.write envelope
        @sut.on 'data', (@result) => done()

      it 'should call onMessage on MahNode after running through christacheio twice', ->
        expect(@result).to.deep.equal
          config: {duckGoes: 'quack'}
          data: {}
          message: {bar: '{{sound}}', sound: 'quack'}

    describe 'when a non-string is passed in', ->
      beforeEach (done) ->
        envelope =
          config: {duckCounts: "{{foo}}"}
          data: {}
          message: {foo: [1,2,3]}

        @sut.write envelope
        @sut.on 'data', (@result) => done()

      it 'should call onMessage on MahNode with the array', ->
        expect(@result).to.deep.equal
          config: {duckCounts: [1,2,3]}
          data: {}
          message: {foo: [1,2,3]}

    describe 'when nesting the key under msg', ->
      beforeEach (done) ->
        envelope =
          config: {duckCounts: "{{msg.foo}}"}
          data: {}
          message: {foo: [1,2,3]}

        @sut.write envelope
        @sut.on 'data', (@result) => done()

      it 'should call onMessage on MahNode with the array', ->
        expect(@result).to.deep.equal
          config: {duckCounts: [1,2,3]}
          data: {}
          message: {foo: [1,2,3]}
