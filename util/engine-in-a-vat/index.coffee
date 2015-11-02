EngineInAVat = require './engine-in-a-vat'
_ = require 'lodash'
flow = require './flows/compose-race-condition.json'
fs = require 'fs'
engineInAVat = new EngineInAVat flowName: 'compose-race-condition', flowData: flow

engineInAVat.initialize (error, configuration)->
  messages = []
  messages2 = []

  router = engineInAVat.triggerByName name: 'Handshake', message: 1
  router2 = engineInAVat.triggerByName name: 'Both', message: 1

  router.on 'data', (envelope) => messages.push envelope
  router2.on 'data', (envelope) => messages2.push envelope

  router.on 'end', => console.log "router1 done"
  router2.on 'end', => console.log "router2 done"

  printRoutes = ->
    fs.writeFileSync './messages.json', JSON.stringify messages, null, 2
    fs.writeFileSync './messages2.json', JSON.stringify messages2, null, 2
    process.exit 0

  setTimeout printRoutes, 5000
