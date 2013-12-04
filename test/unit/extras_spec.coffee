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

  describe "with bound callbacks", ->
    Messages = null

    early = 20131220
    okay  = 20131222
    late  = 20131224

    errorCheck = "It failed."

    # Mock Server on `/messages`
    beforeEach inject ($httpBackend) ->
      id = 0
      _data = [
        {id: ++id, created: early}
        {id: ++id, created: okay}
      ]

      $httpBackend.whenGET('/messages').respond (method, url, data) ->
        log "GET #{url}"
        [200, _data, {}]

      messagesSinceUrl = /\/messages\?since=(\d.*)/
      $httpBackend.whenGET(messagesSinceUrl).respond (method, url, data) ->
        log "GET #{url}"
        since = +messagesSinceUrl.exec(url)[1]

        if since is 42
          return [403, {err: 'Classified'}, {}]

        [
          200
          [{id: ++id, created: late}]
          {}
        ]

      Messages = Collection.new "Messages", {},
        update:
          method: 'GET'
          url: "/messages"
          ###
          # @method Incremental Updates
          #
          # @description This is a great example on how to incremetally update
          #   date using callbacks, since they are bound to have `this` point
          #   to the Collection's `config` object!
          # @param {Object} response HTTP response
          # @return {Object} HTTP response (can be used in chained promises)
          ###
          onSuccess: (response) ->
            if _.isArray response.data
              _.each response.data, (item) =>
                @Data.updateEntry item, @matchingCriteria(item)
            return response
          # Test failure callback by manipulating return value
          onFail: (response) ->
            response.data = errorCheck
            return response

    it "should enable incremental updates", (done) ->
      messages = Messages.all()
      messages.$promise
      .then ->
        expect(messages.all).to.not.contain late
        Messages.update params: since: late
      .then (response) ->
        # console.log response.data
        expect(
          _.pluck messages.all, 'created'
        ).to.contain late

        done(null)
      .then null, (err) ->
        done new Error JSON.stringify err

      tick()

    it "should offer failure handling", (done) ->
      Messages.update(params: since: 42)
      .then ->
        done new Error "Should have been an error."
      .then null, ({data}) ->
        expect(data).to.eql errorCheck
        done(null)

      tick()

