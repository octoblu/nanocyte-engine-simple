#It's a cylinder for the engine. Get it? Pret-ty clever.
EngineInput = require './engine-input'
engineInput = new EngineInput

process.on 'message', engineInput.onMessage

listActiveHandles = ->
  console.log "\n\n=============== HANDLES ============\n\n"
  console.log process._getActiveHandles()
  console.log "\n\n=============== REQUESTS ============\n\n"
  console.log process._getActiveRequests()
setInterval listActiveHandles, 10000
