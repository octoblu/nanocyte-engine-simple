#It's a cylinder for the engine. Get it? Pret-ty clever.
EngineInput = require './engine-input'
engineInput = new EngineInput

process.on 'message', (message) =>
  process.disconnect()
  engineInput.onMessage message
