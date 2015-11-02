{Transform} = require 'stream'
class StreamTester extends Transform
  constructor: () ->
    super objectMode: true
    @onWrite = sinon.stub()
    @onRead = sinon.stub()

  _transform: (envelope) =>
    @onRead envelope
    @onWrite envelope, (error, newEnvelope) =>
      @push newEnvelope

module.exports = StreamTester
