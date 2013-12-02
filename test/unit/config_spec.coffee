describe "Config", ->
  angular.module 'Stuff', ['EpicModel']
  beforeEach module('Stuff')
  beforeEach addHelpers()

  Collection = null
  beforeEach inject (_Collection_) ->
    Collection = _Collection_

  it "can set specific URL", ->
    customUrl = "/api/v2/stuff"
    Things = Collection.new "Things", url: customUrl

    expect(Things.config("url")).to.eql customUrl

  describe "response transformation", ->
    jim = {name: "Jim"}
    arch_enemy = {name: "Arch Enemy"}

    # Mock Server on `/winners`
    beforeEach inject ($httpBackend) ->
      _data = [
        jim
        arch_enemy
        {name: "Some Dude"}
      ]

      $httpBackend.whenGET('/winners').respond (method, url, data) ->
        log "GET /winners"
        [200, _data, {}]

    it "works", (done) ->
      Winners = Collection.new "Winners",
        transformResponse: (data) ->
          if _.isArray(data)
            _.filter data, (item) ->
              item.name isnt "Arch Enemy"
          else data

      winners = Winners.all()
      winners.$promise.then (response) ->
        expect(winners.all).to.have.length.above 0
        expect(winners.all).to.contain jim
        expect(winners.all).to.not.contain arch_enemy

        expect(response.data).to.have.length.above 0
        expect(response.data).to.contain jim
        expect(response.data).to.not.contain arch_enemy

        done(null)
      .then null, (err) ->
        done new Error JSON.stringify err

      tick()

