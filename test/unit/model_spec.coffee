describe "EpicModel", ->
  $q = null
  tick = ->

  beforeEach module('EpicModel')
  beforeEach inject ($rootScope, $httpBackend, _$q_) ->
    $q = _$q_
    tick = ->
      $rootScope.$digest()
      $httpBackend.flush()
      $rootScope.$digest()

  # ## Arrays
  describe "List Resource", ->
    # ### Mock Server
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

      # URL schema: /messages/:id
      messageDetailUrl = /^\/messages\/(\d+)$/

      $httpBackend.whenGET('/messages').respond ->
        console.log "GET /messages"
        [200, messages, {}]

      $httpBackend.whenGET(messageDetailUrl).respond (method, url, data, headers) ->
        id = +messageDetailUrl.exec(url)[1]
        console.log "GET /messages/#{id}"
        [200, _.findWhere(messages, id: id), {}]

      $httpBackend.whenPOST('/messages').respond (method, url, data) ->
        console.log "POST /messages"
        message = angular.fromJson(data)
        message.id = ++id
        messages.push message
        [200, message, {}]

      $httpBackend.whenPOST(messageDetailUrl).respond (method, url, data) ->
        id = messageDetailUrl.exec(url)[1]
        console.log "POST /messages/#{id}"
        message = _.findWhere messages, id: id
        message = data
        [200, message, {}]

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
        updated_message = _.clone(message.data)
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
