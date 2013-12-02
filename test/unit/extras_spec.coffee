describe "Extras", ->
  beforeEach module('EpicModel')
  beforeEach addHelpers

  it 'should be available as functions', inject (Collection) ->
    Specials = Collection.new "Specials", {},
      calculateStuff: (data) ->
        if _.isArray(data)
          _.reduce data, ((memo, val) -> memo + +val.count), 0
        else 42

    sum = Specials.calculateStuff [{count: 3}, {count: 2}]
    expect(sum).to.eql 5
    num = Specials.calculateStuff "hi"
    expect(num).to.eql 42
