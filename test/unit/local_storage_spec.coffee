describe "Local Storage", ->
  angular.module 'Stuff', ['EpicModel']
  beforeEach module('Stuff')
  beforeEach addHelpers()

  Collection = null
  CollectionLocalStorage = null
  beforeEach inject (_Collection_, _CollectionLocalStorage_) ->
    Collection = _Collection_
    CollectionLocalStorage = _CollectionLocalStorage_

  beforeEach inject ($httpBackend) ->
    _data = [1, 42, 13]

    $httpBackend.whenGET('/items').respond (method, url, data) ->
      log "GET #{url}"
      [200, _data, {}]

  it "should be populated after data was loaded", (done) ->
    expect(localStorage).to.exist 
    Items = Collection.new "Items", storage: CollectionLocalStorage

    items = Items.all()
    items.$promise.then ->
      expect(localStorage['Items.all']).to.exist
      done(null)
    .then null, (err) ->
      done new Error JSON.stringify err

    tick()
