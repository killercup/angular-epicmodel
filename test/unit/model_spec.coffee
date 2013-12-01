DEBUG = false
log = if DEBUG then console.log else ->

describe "EpicModel", ->
  $q = null
  tick = ->

  beforeEach module('EpicModel')
  beforeEach inject ($rootScope, $httpBackend, _$q_) ->
    $q = _$q_
    tick = ->
      $rootScope.$digest()
      $httpBackend.flush()

  # ## Arrays
  describe "List Resource", ->
    # ### Mock Server on `/messages`
    beforeEach inject ($httpBackend) ->
      # ^ dummy values
      id = 0
      messages = [
        {
          id: ++id
          subject: 'Hello World'
          body: 'Lorem Ipsum'
        }
        {
          id: ++id
          subject: 'Hi There'
          body: 'Dolor sit amet'
        }
      ]

      # URL schema: `/messages/:id`
      messageDetailUrl = /^\/messages\/(\d+)$/

      $httpBackend.whenGET('/messages').respond ->
        log "GET /messages"
        [200, messages, {}]

      $httpBackend.whenGET(messageDetailUrl).respond (method, url, data, headers) ->
        id = +messageDetailUrl.exec(url)[1]
        log "GET /messages/#{id}"
        [200, _.findWhere(messages, id: id), {}]

      $httpBackend.whenPOST('/messages').respond (method, url, data) ->
        log "POST /messages"
        message = angular.fromJson(data)
        message.id = ++id
        messages.push message
        [200, message, {}]

      $httpBackend.whenPOST(messageDetailUrl).respond (method, url, data) ->
        id = +messageDetailUrl.exec(url)[1]
        log "POST /messages/#{id}"
        message = _.findWhere messages, id: id
        message = data
        [200, message, {}]

      $httpBackend.whenDELETE(messageDetailUrl).respond (method, url, data) ->
        id = +messageDetailUrl.exec(url)[1]
        log "DELETE /messages/#{id}"
        message = _.findWhere messages, id: id
        recover = _.cloneDeep(message)
        delete messages[messages.indexOf(message)]
        [200, recover, {}]

    # ### Initialize new Collection each time
    Messages = null
    beforeEach inject (Collection) ->
      Messages = Collection.new "Messages"

    # ### GET /messages
    it "should fetch an array of objects", (done) ->
      messages = Messages.all()

      messages.$promise.then ->
        expect(messages.all.length).to.eql(2)
        done(null)
      .then null, (err) ->
        done new Error JSON.stringify err

      tick()

    # ### GET /messages/2
    it 'should fetch single item', (done) ->
      query = id: 2

      messages = Messages.all()
      message = Messages.get(query)

      $q.all([messages.$promise, message.$promise]).then ->
        expect(messages.all).to.exist

        expect(message.data).to.exist

        expect(_.findWhere(messages.all, query)).to.eql(message.data)

        expect(message.data.subject).to.eql('Hi There')
        done(null)
      .then null, (err) ->
        done new Error JSON.stringify err

      tick()

    # ### POST /messages
    xit 'should create a new entry', (done) ->
      new_message =
        subject: "Fresh Start"
        body: "Brand new message"

      message = Messages.create(new_message)
      message.$promise.then ->
        expect(message.data.id).toBeDefined()
        done()
      tick()

    # ### POST /messages/1
    it 'should update an entry', (done) ->
      query = id: 1
      message = Messages.get(query)

      err = (err) ->
        done new Error JSON.stringify err

      message.$promise.then (data) ->
        expect(message.data.subject).to.exist

        old_subject = message.data.subject
        new_subject = 'Shiny Message'

        # Clone message and edit the clone so it is a new reference
        updated_message = _.cloneDeep(message.data)
        updated_message.subject = new_subject

        saved_message = Messages.save(updated_message)

        success = (data) ->
          expect(data.subject).to.eql new_subject
          expect(data.subject).to.eql message.data.subject
          expect(data.body).to.eql message.data.body
          done(null)

        saved_message.then success, err
      .then null, err

      tick()

    # ### DELETE /messages/2
    it 'should delete an entry', (done) ->
      query = id: 2
      Messages.destroy(query)
      .then ->
        messages = Messages.where query
        expect(messages).to.be.an('array')
        expect(messages.length).to.eql 0
        done(null)
      .then null, (err) ->
        done new Error JSON.stringify err

      tick()

    # ### Query cached data
    it 'should query cached data', (done) ->
      Messages.all().$promise
      .then ->
        messages = Messages.where subject: 'Hello World'
        expect(messages).to.be.an('array')
        expect(messages.length).to.eql 1
        done(null)
      .then null, (err) ->
        done new Error JSON.stringify err

      tick()


  # ## Singleton Objects
  describe "Singleton Resource", ->
    # ### Mock Server on `/me`
    beforeEach inject ($httpBackend) ->
      _data =
        name: "Pascal"
        awesomeness: 42

      $httpBackend.whenGET('/me').respond (method, url, data) ->
        log "GET /me"
        [200, _data, {}]

      $httpBackend.whenPOST('/me').respond (method, url, data) ->
        log "POST /me", data
        _data = _.extend(data, _data)
        log "new data", _data
        [200, _data, {}]

    # ### Initialize new Collection each time
    Me = null
    beforeEach inject (Collection) ->
      Me = Collection.new "Me", is_singleton: true

    it 'should fetch an object', (done) ->
      me = Me.all()

      me.$promise.then ->
        expect(me.data).to.be.an('object')
        expect(me.data).to.contain.keys('name', 'awesomeness')
        done(null)
      .then null, (err) ->
        done new Error JSON.stringify err

      tick()

    it 'should update an object', (done) ->
      oldMe = me = Me.all()

      me.$promise.then ->
        oldMe = _.cloneDeep(me)
        log "awesomeness", me.data.awesomeness
        me.data.awesomeness += 1
        log "awesomeness", me.data.awesomeness
        Me.save(me.data)
      .then (newMe) ->
        expect(newMe.awesomeness).to.be.above oldMe.data.awesomeness
        expect(newMe.name).to.eql oldMe.data.name

        done(null)
      .then null, (err) ->
        done new Error JSON.stringify err

      tick()

