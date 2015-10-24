path             = require 'path'
_                = require 'lodash'
RouterRunner = require '../router-runner'

runnerConfig = require path.join __dirname, './compose-race-condition-config.json'

runner = new RouterRunner runnerConfig

runner.initialize =>
  routerStream = runner.triggerByName 'Handshake', {handshake: 'down-low'}
  routerStream = runner.triggerByName 'Greeting', {handshake: 'down-low'}

  routerStream.on 'data', (data) => console.log "router said", data
