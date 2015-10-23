EngineRunner = require './engine-runner'
_            = require 'lodash'

class TriggerComponent extends EngineRunner
  before: (done=->) =>
    super =>
      @triggerNodemessage = => @triggerNodemessage.done()
      @fakeOutComponent 'nanocyte-component-trigger', @triggerNodemessage
      _.defer done

  after: (done=->) =>
    super =>
      @restoreComponent 'nanocyte-component-trigger'
      _.defer done

module.exports = TriggerComponent
