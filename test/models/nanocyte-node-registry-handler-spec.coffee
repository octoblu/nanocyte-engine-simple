NanocyteNodeRegistryHandler = require '../../src/models/nanocyte-node-registry-handler'
describe 'NanocyteNodeRegistryHandler', ->
  describe '->constructor', ->
    beforeEach ->
      @sut = new NanocyteNodeRegistryHandler

    it 'should exist', ->
      expect(@sut).to.exist


  describe '->getComponentMap', ->
    beforeEach ->
      @request = sinon.stub()

      @registry =
        horns: 2
        teeth: 'too many'

      @sut = new NanocyteNodeRegistryHandler(
        {registryUrl: "http://upset.men/registry.json"}
        {request: @request}
      )

      @sut.getComponentList = sinon.spy()

    describe 'when called', ->
      beforeEach (done) ->
        @request.yields null, null, @registry
        @sut.getComponentMap (@error, @result) => done()

      it 'should get the node registry with request', ->
        expect(@request).to.have.been.calledWith url: "http://upset.men/registry.json", json: true

      it 'should call getComponentMapForNode for each node in the registry', ->
        expect(@sut.getComponentList).to.have.been.calledWith @registry

    describe 'when request returns an error', ->
      beforeEach (done) ->
        @request.yields new Error 'This beast is too majestic'
        @sut.getComponentMap (@error, @result) => done()

      it 'should call the callback with an error', ->
        expect(@error).to.exist

  describe '->getComponentList', ->
    beforeEach ->
      @sut = new NanocyteNodeRegistryHandler
      @registry =
        broadcast:
          composedOf:
            broadcast:
              type: "nanocyte-component-broadcast"
              linkedToPrev: true
              linkedToOutput: true
              linkedToPulse: true
        change:
          composedOf:
            change:
              type: "nanocyte-component-change"
              linkedToPrev: true
              linkedToNext: true
              linkedToData: true
        channel:
          composedOf:
            "octoblu-channel":
              type: "nanocyte-component-octoblu-channel-request-formatter"
              linkedToPrev: true
              linkedTo: [
                "http-request"
              ]
            "http-request":
              type: "nanocyte-component-http-request"
              linkedTo: [
                "parse-body"
              ]
            "parse-body":
              type: "nanocyte-component-body-parser"
              linkedToNext: true

      @result = @sut.getComponentList @registry

    it 'should return a unique list of nanocyte components needed to support the current registry', ->
      expect(@result).to.have.same.members [
        "nanocyte-component-body-parser"
        "nanocyte-component-broadcast"
        "nanocyte-component-change"
        "nanocyte-component-http-request"
        "nanocyte-component-octoblu-channel-request-formatter"
      ]

  describe '->loadComponentClass', ->
    beforeEach ->
      class ComponentBroadcast
      @ComponentBroadcast = ComponentBroadcast

      class ComponentChange
      @ComponentChange = ComponentChange

      componentClasses = 'nanocyte-component-broadcast': ComponentBroadcast, 'nanocyte-component-change': ComponentChange
      @sut = new NanocyteNodeRegistryHandler {}, {componentClasses: componentClasses}
      @componentBroadcastClass = @sut.loadComponentClass 'nanocyte-component-broadcast'
      @componentChangeClass = @sut.loadComponentClass 'nanocyte-component-change'

    it 'should return the correct component class for broadcast', ->
      expect(@componentBroadcastClass).to.equal @ComponentBroadcast

    it 'should return the correct component class for change', ->
      expect(@componentChangeClass).to.equal @ComponentChange
