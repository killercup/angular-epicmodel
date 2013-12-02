describe "Singleton Resource", ->
  angular.module 'Stuff', ['EpicModel']
  beforeEach module('Stuff')
  beforeEach addHelpers()

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
      me.data.awesomeness += 1
      Me.save(me.data)
    .then (newMe) ->
      expect(newMe.awesomeness).to.be.above oldMe.data.awesomeness
      expect(newMe.name).to.eql oldMe.data.name

      done(null)
    .then null, (err) ->
      done new Error JSON.stringify err

    tick()

  it 'should not be able to retrieve a detail resource', ->
    expect(-> Me.get id: 1).to.throw(Error)

  it 'should not be able to destroy resource', ->
    expect(Me.destroy).to.throw(Error)

  it 'should not be able to create entry', ->
    expect(Me.create).to.throw(Error)
