describe "List Resource", ->
  angular.module 'Stuff', ['EpicModel']
  beforeEach module('Stuff')
  beforeEach addHelpers()

  # static values, DRY
  subject2 = 'Hi There'
  messagesCount = 0

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
        subject: subject2
        body: 'Dolor sit amet'
      }
    ]
    messagesCount = messages.length

    # URL schema: `/messages/:id`
    messageDetailUrl = /^\/messages\/(\d+)$/

    $httpBackend.whenGET('/messages').respond ->
      log "GET /messages"
      [200, messages, {}]

    $httpBackend.whenGET(messageDetailUrl).respond (method, url, data, headers) ->
      id = +messageDetailUrl.exec(url)[1]
      log "GET /messages/#{id}"
      if id is 42
        return [403, {err: 'Access Denied', msg: 'Classified'}, {}]
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

  afterEach inject ($httpBackend) ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()

  # ### Initialize new Collection each time
  Messages = null
  beforeEach inject (Collection) ->
    Messages = Collection.new "Messages"

  # ### GET /messages
  describe "concerning all items", ->
    it "should fetch an array of objects", (done) ->
      messages = Messages.all()

      messages.$promise.then ->
        expect(messages.$resolved).to.eql true
        expect(messages.all.length).to.eql messagesCount
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

    it "should have a 'loading' flag", (done) ->
      messages = Messages.all()
      expect(messages.$loading).to.eql true

      messages.$promise.then ->
        expect(messages.$loading).to.eql false
        expect(messages.$resolved).to.eql true
        done(null)
      .then null, (err) ->
        done new Error JSON.stringify err

      tick()

  describe "concerning a single item", ->
    # ### GET /messages/2
    it 'should fetch single item', (done) ->
      query = id: 2

      messages = Messages.all()
      message = Messages.get(query)

      $q.all([messages.$promise, message.$promise]).then ->
        expect(messages.all).to.exist
        expect(messages.$resolved).to.eql true

        expect(message.data).to.exist
        expect(message.$resolved).to.eql true

        expect(_.findWhere(messages.all, query)).to.eql(message.data)

        expect(message.data.subject).to.eql subject2
        done(null)
      .then null, (err) ->
        done new Error JSON.stringify err

      tick()

    it 'should not fetch a single item without an ID', (done) ->
      message = Messages.get({})
      message.$promise
      .then (data) ->
        done new Error "Incorrect message was saved."
      .then null, (err) ->
        expect(message.$resolved).to.not.be.ok
        expect(err).to.exist
        done(null)

      tick()

    it "should have a 'loading' flag", (done) ->
      message = Messages.get id: 2
      expect(message.$loading).to.eql true

      message.$promise.then ->
        expect(message.$loading).to.eql false
        expect(message.$resolved).to.eql true
        done(null)
      .then null, (err) ->
        done new Error JSON.stringify err

      tick()

    # ### POST /messages/1
    it 'should update an entry', (done) ->
      query = {}
      messages = []
      message = {}

      new_subject = 'Shiny Message'

      # Fetch all messages for reference
      messages = Messages.all()
      messages.$promise.then ->
        # Load random message
        query = id: _.sample(messages.all).id
        message = Messages.get(query)
        message.$promise
      .then ->
        expect(message.data.subject).to.exist

        # Clone message and edit the clone so it is a new reference
        updated_message = _.cloneDeep(message.data)
        updated_message.subject = new_subject

        # Save correctly
        Messages.save(updated_message)
      .then (data) ->
        # message object updated
        expect(data.subject).to.eql new_subject
        expect(data.subject).to.eql message.data.subject
        expect(data.body).to.eql message.data.body

        # messages list item updated
        expect(_.findWhere(messages.all, query)).to.deep.equal(data)

        $q.when data
      .then ->
        done(null)
      .then null, (err) ->
        done new Error JSON.stringify err

      tick()

    it "should not update an entry without an ID", (done) ->
      Messages.save({}).then (data) ->
        done new Error "Incorrect message was saved."
      .then null, (err) ->
        expect(err).to.exist
        done(null)

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

    it 'should not delete an entry without an ID', (done) ->
      Messages.destroy({}).then (data) ->
        done new Error "Incorrect message was saved."
      .then null, (err) ->
        expect(err).to.exist
        done(null)

      tick()

  # ### POST /messages
  it 'should create a new entry', (done) ->
    new_message =
      subject: subject = "Fresh Start"
      body: body = "Brand new message"

    Messages.create(new_message)
    .then (message) ->
      expect(message.id).to.exist
      expect(message.subject).to.eql subject
      expect(message.body).to.eql body
      done()
    .then null, (err) ->
      done new Error JSON.stringify err
    tick()

  it "should reject promise on HTTP error", (done) ->
    Messages.get(id: 42).$promise
    .then (data) ->
      done new Error "HTTP error did not reject promise."
    .then null, (err) ->
      expect(err).to.exist
      done(null)

    tick()
