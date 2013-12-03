describe "Collection", ->
  angular.module 'Stuff', ['EpicModel']
  beforeEach module('Stuff')

  beforeEach addHelpers()

  Collection = null
  beforeEach inject (_Collection_) ->
    Collection = _Collection_

  describe "creation", ->

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

  describe "has data methods that", ->
    it "can read data from lists", ->
      Things = Collection.new "Things"

      expect(Things.Data).to.respondTo("get")
      expect(Things.Data.get()).to.be.an("array")

    it "can read data from singletons", ->
      Profile = Collection.new "Profile", is_singleton: true
      expect(Profile.Data.get()).to.be.an("object")

    it "can add entries to lists", ->
      Things = Collection.new "Things"

      expect(Things.Data.get()).to.be.length 0

      Things.Data.updateEntry name: "Jim"
      expect(Things.Data.get()).to.be.length 1

    it "can replace data in lists", ->
      Things = Collection.new "Things"

      expect(Things.Data.get()).to.be.length 0

      Things.Data.replace [1..4]
      expect(Things.Data.get()).to.be.length 4

    it "can replace data in singletons", ->
      Profile = Collection.new "Profile", is_singleton: true
      expect(Profile.Data.get()).to.eql {}

      Profile.Data.replace name: "Jim"
      expect(Profile.Data.get()).to.eql name: "Jim"

    it "can remove entries from lists", ->
      Things = Collection.new "Things"
      Things.Data.updateEntry name: "Jim"
      expect(Things.Data.get()).to.be.length 1

      hit = Things.Data.removeEntry name: "Jim"
      expect(hit).to.be.ok

      expect(Things.Data.get()).to.be.length 0
