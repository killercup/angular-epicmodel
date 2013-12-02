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
        {name: "Some Dude", occupation: 'Sofa Tester'}
      ]

      # URL schema: `/winners/:id`
      winnerDetailUrl = /^\/winners\/(\d+)$/

      $httpBackend.whenGET('/winners').respond (method, url, data) ->
        log "GET /winners"
        [200, _data, {}]

      $httpBackend.whenGET(winnerDetailUrl).respond (method, url, data, headers) ->
        id = +winnerDetailUrl.exec(url)[1]
        log "GET /winner/#{id}"
        [200, _data[id], {}]

      $httpBackend.whenPOST(winnerDetailUrl).respond (method, url, data, headers) ->
        id = +winnerDetailUrl.exec(url)[1]
        log "POST /winner/#{id}"
        [200, _data[id], {}]

    Winners = null
    beforeEach inject (Collection) ->
      Winners = Collection.new "Winners",
        transformResponse: (data) ->
          if _.isArray(data)
            _.filter data, (item) ->
              item.name isnt arch_enemy.name
          else if _.isObject(data)
            _.extend data, {age: 42}
          else data

    it "works with list resources", (done) ->
      winners = Winners.all()
      winners.$promise.then (response) ->
        expect(winners.all).to.have.length.above 0
        expect(winners.all).to.contain jim
        expect(winners.all).to.not.contain arch_enemy

        expect(response.data).to.deep.eql(winners.all)

        done(null)
      .then null, (err) ->
        done new Error JSON.stringify err

      tick()

    it 'works with detail resource', (done) ->
      winner = Winners.get(id: 1)
      winner.$promise.then ->
        expect(winner.data.age).to.exist

        done(null)
      .then null, (err) ->
        done new Error JSON.stringify err

      tick()

    it 'works with saved resource', (done) ->
      Winners.save(id: 1, name: "New Friend")
      .then (winner) ->
        expect(winner.age).to.exist

        done(null)
      .then null, (err) ->
        done new Error JSON.stringify err

      tick()
