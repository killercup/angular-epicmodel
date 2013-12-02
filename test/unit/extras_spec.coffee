describe "Extras", ->
  angular.module 'Stuff', ['EpicModel']
  beforeEach module('Stuff')
  beforeEach addHelpers()

  Collection = null
  beforeEach inject (_Collection_) ->
    Collection = _Collection_

  describe 'as functions', ->
    it 'should be available', ->
      Specials = Collection.new "Specials", {},
        calculateStuff: (data) ->
          if _.isArray(data)
            _.reduce data, ((memo, val) -> memo + +val.count), 0
          else 42

      sum = Specials.calculateStuff [{count: 3}, {count: 2}]
      expect(sum).to.eql 5
      num = Specials.calculateStuff "hi"
      expect(num).to.eql 42

    it 'should have Collection config as scope', ->
      specialBaseUrl = 'https://example.com/api/v42'
      specialUrl = '/1337'

      Thingy = Collection.new "Thingy", {
        baseUrl: specialBaseUrl
        url: specialUrl
      },
        allYourBases: -> @baseUrl
        whatsThisUrl: -> @url

      expect(Thingy.allYourBases()).to.eql specialBaseUrl
      expect(Thingy.whatsThisUrl()).to.eql specialUrl

  describe 'as HTTP calls', ->
    # Mock Server on `/me/friends`
    beforeEach inject ($httpBackend) ->
      _data = [
        {name: "Jim"}
        {name: "Some Dude"}
      ]

      $httpBackend.whenGET('/me/friends').respond (method, url, data) ->
        log "GET /me/friends"
        [200, _data, {}]

    it 'should work', (done) ->
      Me = Collection.new "Me", {is_singleton: true},
        friends:
          method: 'GET'
          url: '/me/friends'

      expect(Me.friends).to.be.a('function')

      friends = Me.friends()
      expect(friends).to.respondTo('then')

      friends.then (response) ->
        expect(response.data).to.exist
        expect(response.data).to.have.deep.property('[1].name')

        done(null)
      .then null, (err) ->
        done new Error JSON.stringify err

      tick()
