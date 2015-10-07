ComponentLoader = require '../../src/models/component-loader'
describe 'ComponentLoader', ->
  beforeEach ->
    @request = sinon.stub()

    class ComponentBroadcast
    @ComponentBroadcast = ComponentBroadcast

    class ComponentChange
    @ComponentChange = ComponentChange

    componentClasses = 'nanocyte-component-broadcast': @ComponentBroadcast, 'nanocyte-component-change': @ComponentChange, 'too many': @ComponentChange
    @sut = new ComponentLoader {registryUrl: "http://upset.men/registry.json"}, {request: @request, componentClasses: componentClasses}

  it 'should exist', ->
    expect(@sut).to.exist


  describe '->getComponentMap', ->
    beforeEach ->
      @registry =
        horns:
          composedOf:
            leftHorn:
              type: 'nanocyte-component-broadcast'
        teeth:
          composedOf:
            fang:
              type: 'nanocyte-component-change'
            molar:
              type: 'nanocyte-component-change'

    describe 'when called', ->
      beforeEach (done) ->
        @request.yields null, null, @registry
        @sut.getComponentMap (@error, @result) => done()

      it 'should get the node registry with request', ->
        expect(@request).to.have.been.calledWith url: "http://upset.men/registry.json", json: true

      it 'should return the correct registry', ->
        expect(@result).to.deep.equal
          'nanocyte-component-broadcast': @ComponentBroadcast
          'nanocyte-component-change': @ComponentChange

    describe 'when request returns an error', ->
      beforeEach (done) ->
        @request.yields new Error 'This beast is too majestic'
        @sut.getComponentMap (@error, @result) => done()

      it 'should call the callback with an error', ->
        expect(@error).to.exist

  describe '->getComponentList', ->
    beforeEach ->
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
      @componentBroadcastClass = @sut.loadComponentClass 'nanocyte-component-broadcast'
      @componentChangeClass = @sut.loadComponentClass 'nanocyte-component-change'

    it 'should return the correct component class for broadcast', ->
      expect(@componentBroadcastClass).to.equal @ComponentBroadcast

    it 'should return the correct component class for change', ->
      expect(@componentChangeClass).to.equal @ComponentChange
