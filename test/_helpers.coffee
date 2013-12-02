###
# # Helpers
#
# Add some global methods do make life easier.
#
# Also: Globals are bad (troll)
###
DEBUG = false
log = if DEBUG then console.log else ->

$q = null
tick = ->

addHelpers = inject ($rootScope, $httpBackend, _$q_) ->
  $q = _$q_

  # @method
  # @description
  # Trigger digest cycle to make Angular process `$http` and promises.
  # Also flushes `$httpBackend` to prevent disaster.
  tick = (flush=true) ->
    $rootScope.$digest()
    $httpBackend.flush() if flush
