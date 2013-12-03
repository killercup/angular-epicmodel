###
# Test Config for Single Requests
#
# Most methods have an additional argument for HTTP options.
#
# @example
# ```coffeescript
# Items.get {id: 42}, params: {include: 'comments'}
# ```
###
describe "Request Config", ->
  angular.module 'Stuff', ['EpicModel']
  beforeEach module('Stuff')
  beforeEach addHelpers()

  Collection = null
  beforeEach inject (_Collection_) ->
    Collection = _Collection_

  specialValue = 'param'

  # ### Mock Server on `/items`
  beforeEach inject ($httpBackend) ->
    _data = [1, 42, 13]

    $httpBackend.whenGET('/items').respond (method, url, data) ->
      log "GET #{url}"
      [200, _data, {}]

    $httpBackend.whenGET(/\/items\?(\w*)/).respond (method, url, data) ->
      log "GET #{url}", data
      [200, [specialValue], {}]

    # URL schema: `/items/:id`
    itemsDetailUrl = /^\/items\/(\d+)$/

    $httpBackend.whenGET(itemsDetailUrl).respond (method, url, data, headers={}) ->
      if headers.Authorization?
        [200, {special: specialValue}, {}]
      else
        [403, {err: 'no auth'}, {}]

  # ## List Resource
  it "can set parameters for all()", (done) ->
    Items = Collection.new "Items"

    things = Items.all params: {special: true}
    things.$promise.then ->
      expect(things.all).to.have.length(1)
      expect(things.all[0]).to.eql specialValue

      done(null)
    .then null, (err) ->
      done new Error JSON.stringify err

    tick()

  # ## Detail Resource
  it "can set headers", (done) ->
    Items = Collection.new "Items"
    auth = Authorization: "Token 1337"

    thingy = Items.get {id: 1}
    thingy.$promise.then ->
      done new Error "Should throw 403 ($httpBackend config)"
    .then null, ({status, data}) ->
      expect(status).to.eql 403
      expect(data).to.have.property('err')

      # now with auth header
      thingy = Items.get {id: 1}, headers: auth
      thingy.$promise
    .then ({status}) ->
      expect(status).to.eql 200
      expect(thingy.data.special).to.eql specialValue
      done(null)
    .then null, (err) ->
      done new Error JSON.stringify err

    tick()
