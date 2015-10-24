path             = require 'path'
_                = require 'lodash'
RouterRunner = require '../router-runner'

runnerConfig = require path.join __dirname, './compose-race-condition-config.json'

runner = new RouterRunner runnerConfig


runner.triggerByName 'Handshake', {the: 'message'}
