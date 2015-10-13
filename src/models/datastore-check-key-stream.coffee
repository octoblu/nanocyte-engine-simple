_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:datastore-check-key-stream')
{Transform} = require 'stream'

class DatastoreCheckKeyStream extends Transform
  constructor: (options, dependencies={}) ->
    super objectMode: true
    {@datastore} = dependencies
    @datastore ?= new (require './datastore')

  _transform: (envelope, enc, next) =>
    debug '_transform', envelope

    @datastore.exists "pulse:#{envelope.flowId}", (error, exists) =>
      @push envelope if exists == 1
      @push null
      next()

module.exports = DatastoreCheckKeyStream
