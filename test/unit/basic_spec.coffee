describe "Collection", ->
  angular.module 'Stuff', ['EpicModel']
  beforeEach module('Stuff')

  describe "creation", ->
    beforeEach addHelpers()

    Collection = null
    beforeEach inject (_Collection_) ->
      Collection = _Collection_

    it "works with a name", ->
      Things = Collection.new "Things"
      expect(Things).to.be.an('object')
      expect(Things).to.have.property('all')

    it "infers URL from name", ->
      Things = Collection.new "Things"
      expect(Things.config('url')).to.eql('/things')

    it "doesn't work without name", ->
      expect(->
        Collection.new()
      ).to.throw(Error)
