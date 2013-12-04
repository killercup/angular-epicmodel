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

  describe "for custom detail URLs", ->
    describe "using string matching", ->
      it "works", ->
        Things = Collection.new "Things", detailUrl: "/thingies/{_id}"

        expect(Things.config('url')).to.eql '/things'

        detailUrl = Things.config('getDetailUrl')
        expect(detailUrl).to.be.a('function')

        expect(detailUrl(_id: 42)).to.eql '/thingies/42'

      it "fails with incorrect substitution schema", ->
        Things = Collection.new "Things", detailUrl: "/thingies/{_id"

        detailUrl = Things.config('getDetailUrl')
        expect(detailUrl).to.be.a('function')

        expect(detailUrl(_id: 42)).to.not.eql '/thingies/42'

      it "works for complex substitutions", ->
        Properties = Collection.new "Properties",
          detailUrl: "/thingies/{item._id}/properties/{_id}"

        detailUrl = Properties.config('getDetailUrl')
        expect(detailUrl).to.be.a('function')

        testUrl = detailUrl _id: 42, item: {_id: 21}
        expect(testUrl).to.eql '/thingies/21/properties/42'

      it "fails when fields are missing", ->
        Things = Collection.new "Things", detailUrl: "/thingies/{_id}"

        detailUrl = Things.config('getDetailUrl')
        expect(detailUrl).to.be.a('function')

        expect(-> detailUrl(name: 'Jim')).to.throw Error

    describe "using a function", ->
      it "works", ->
        Things = Collection.new "Things",
          detailUrl: (entry, listUrl, baseUrl) ->
            throw new Error unless entry.name?
            "#{baseUrl}/thingies/#{entry.name}"

        expect(Things.config('url')).to.eql '/things'

        detailUrl = Things.config('getDetailUrl')
        expect(detailUrl).to.be.a('function')

        expect(detailUrl(name: 'Chair')).to.eql '/thingies/Chair'

      it "fails when fields are missing", ->
        # Actually, you should check this yourself!
        Things = Collection.new "Things",
          detailUrl: (entry, listUrl, baseUrl) ->
            throw new Error unless entry.name?
            "#{baseUrl}/thingies/#{entry.name}"

        detailUrl = Things.config('getDetailUrl')

        expect(-> detailUrl(id: 12)).to.throw Error
