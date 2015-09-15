_ = require 'lodash'
async = require 'async'

class WrapperFactory
  constructor: (options={}) ->
    {@nodeClasses} = options

  onEnvelope: (envelope, callback) =>
    functions = []
    functions.push (cb) => cb null, envelope

    _.each @nodeClasses, (klass) => functions.push (new klass).onEnvelope

    async.waterfall functions, callback

module.exports = WrapperFactory
