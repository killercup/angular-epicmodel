describe "List Resource", ->
  angular.module 'Stuff', ['EpicModel']
  beforeEach module('Stuff')
  beforeEach addHelpers()

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

  # ### POST /messages/1
  it 'should update an entry', (done) ->
    query = id: 1
    message = Messages.get(query)

    message.$promise.then (data) ->
      expect(message.data.subject).to.exist

      old_subject = message.data.subject
      new_subject = 'Shiny Message'

      # Clone message and edit the clone so it is a new reference
      updated_message = _.cloneDeep(message.data)
      updated_message.subject = new_subject

      # Save correctly
      saved_message = Messages.save(updated_message)

      saved_message.then (data) ->
        expect(data.subject).to.eql new_subject
        expect(data.subject).to.eql message.data.subject
        expect(data.body).to.eql message.data.body
        $q.when data
    .then ->
      # Save invalid data
      Messages.save({}).then (data) ->
        done new Error "Incorrect message was saved."
      .then null, (err) ->
        expect(err).to.exist
        done(null)
    .then null, (err) ->
      done new Error JSON.stringify err

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
