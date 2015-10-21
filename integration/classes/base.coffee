_  = require 'lodash'

class Base
  before: (callback=->) =>
    _.defer callback

  after: (callback=->) =>
    _.defer callback

module.exports = Base
