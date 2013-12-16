describe "Global config", ->
  angular.module 'Stuff', ['EpicModel']
  beforeEach module('Stuff')

  demoUrl = 'https://example.com/api/v42/'

  it "sets baseUrl correctly", ->
    module (CollectionProvider) ->
      CollectionProvider.setBaseUrl demoUrl
      # Return nothing because Angular will try to inject return value!
      return

    inject ($http, Collection) ->
      Things = Collection.new "Things"
      expect(Things.config('baseUrl')).to.eql(demoUrl)
      return
