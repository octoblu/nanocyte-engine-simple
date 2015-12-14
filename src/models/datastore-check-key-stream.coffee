_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:datastore-check-key-stream')
{Transform} = require 'stream'

class DatastoreCheckKeyStream extends Transform
  constructor: (options, dependencies={}) ->
    super objectMode: true
    {@flowId} = options
    {@datastore} = dependencies
    @datastore ?= new (require './datastore') options, dependencies

  _transform: (message, enc, next) =>
    @datastore.exists "pulse:#{@flowId}", (error, exists) =>
      if exists == 1
        @push message
      else
        @push null

      next()

module.exports = DatastoreCheckKeyStream
