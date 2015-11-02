{Transform} = require 'stream'
json3 = require 'json3'
debug = require('debug')('nanocyte-engine-simple:engine-output')

class SerializersStream extends Transform
  constructor: (options={}, dependencies={})->
    super objectMode: true

  _transform: (message, enc, done) =>
    msgString = json3.stringify message
    @push msgString
    done()

module.exports = SerializersStream
