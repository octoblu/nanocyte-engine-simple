_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:datastore-check-key-stream')
{Transform} = require 'stream'

class DatastoreCheckKeyStream extends Transform
  constructor: (options, dependencies={}) ->
    super objectMode: true
    {@flowId} = options
    {@datastore} = dependencies
    @datastore ?= new (require './datastore')

  _transform: (envelope, enc, next) =>
    debug '_transform', envelope

    @datastore.exists "pulse:#{@flowId}", (error, exists) =>
      @push envelope if exists == 1
      next()

module.exports = DatastoreCheckKeyStream
