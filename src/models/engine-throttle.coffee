{Transform} = require 'stream'
debug       = require('debug')('nanocyte-engine-simple:engine-throttle')
_           = require 'lodash'

class EngineThrottle extends Transform
  constructor: (options, dependencies={})->
    {@datastore, @moment} = dependencies
    super objectMode: true

  _transform: (envelope, enc, next) =>
    envelope = _.cloneDeep envelope
    {config} = envelope

    key = "#{config.uuid}:#{@moment().unix()}"
    @datastore.getAndIncrementCount key, (error, count) =>
      if count == 10
        envelope.message.devices = ['*']
        envelope.message.payload = {msgType: 'error', message: 'Engine rate limit exceeded'}

      @push envelope unless count > 10
      @push null

    next()

  _getCountAndIncrement: (key, callback) =>
    @_getCount key, (error, count) =>
      return callback error if error?

      @_incrementCount key, (error) =>
        callback error, count


  _getCount: (key, callback) =>
    @datastore.get key, callback

  _incrementCount: (key, callback) =>
    @datastore
      .multi()
      .incr   key, 1
      .expire key, 10
      .exec callback

module.exports = EngineThrottle

# FUNCTION LIMIT_API_CALL(ip)
# ts = CURRENT_UNIX_TIME()
# keyname = ip+":"+ts
# current = GET(keyname)
# IF current != NULL AND current > 10 THEN
#     ERROR "too many requests per second"
# ELSE
#     MULTI
#         INCR(keyname,1)
#         EXPIRE(keyname,10)
#     EXEC
#     PERFORM_API_CALL()
# END
