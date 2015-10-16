EngineRunner = require './engine-runner'
_            = require 'lodash'

class TriggerComponent extends EngineRunner
  before: (done=->) =>
    super =>
      @triggerNodeOnMessage = => @triggerNodeOnMessage.done()
      @fakeOutComponent 'nanocyte-component-trigger', @triggerNodeOnMessage
      _.defer done

  after: (done=->) =>
    super =>
      @restoreComponent 'nanocyte-component-trigger'
      _.defer done

module.exports = TriggerComponent
