_ = require 'lodash'
async = require 'async'

class WrapperFactory
  constructor: ({wrappers: @wrappers}) ->

  onEnvelope: (envelope, callback) =>
    functions = []
    functions.push (cb) => cb null, envelope
    functions = functions.concat _.pluck(@wrappers, 'onEnvelope')

    async.waterfall functions, callback

module.exports = WrapperFactory
