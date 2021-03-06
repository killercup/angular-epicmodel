###
# # Epic Model
###
angular.module('EpicModel', [
])

.provider "Collection", ->
  ###
  # Create your own collection by injecting the `Collection` service and calling
  # its 'new' method.
  #
  # @example
  # ```coffeescript
  # angular.module('Module', ['EpicModel'])
  # .factory "API", (Collection) ->
  #   API =
  #     People: Collection.new 'People', {url: '/people/:id'},
  #       calculateStuff: (input) -> 42
  # .controller "Ctrl", ($scope, ShittyAPI) ->
  #   $scope.list = API.People.all()
  # ```
  #
  # **Immediate Return Data**
  #
  # Most methods return a promise, but the methods `all` and `get` methods
  # return a special object instead, that contains the currently available data,
  # a promise and flags to represent the data retrieval state. I.e., you can
  # immediately use the return value in your views and the data will
  # automatically appear once it has been retrieved (or updated).
  #
  # @example
  # ```coffeescript
  # Me = Collection.new "Me", is_singleton: true
  # Me.all()
  # #=> {data: {}, $resolved: false, $loading: true, $promise: {then, ...}}
  # ```
  ###

  # ## Global Config
  ###
  #
  # Just inject the `CollectionProvider` and set some globals.
  #
  # @example
  # ```coffeescript
  # angular.module('app', ['EpicModel'])
  # .config (CollectionProvider) ->
  #   CollectionProvider.setBaseUrl('http://example.com/api/v1')
  # ```
  ###
  globalConfig =
    baseUrl: ''

  ###
  # @method Set Base URL
  #
  # @param {String} url The new base URL
  # @return {String} The new base URL
  # @throws {Error} When no URL is given
  ###
  @setBaseUrl = (url='') ->
    throw new Error "No URL given." unless url?
    globalConfig.baseUrl = url

  # - - -
  #
  # The service factory function
  @$get = ($q, $http) ->
    ###
    # ## Constructor
    #
    # Create a new Collection.
    #
    # @param {String} name The unique name of the new collection.
    # @param {Object} [config] Configuration and settings
    # @param {String|Function} [config.url] Resource URL
    # @param {String|Function} [config.detailUrl] URL for single resource,
    #   default: `config.url + '/' + entry.id`. Will interpolate segments in
    #   curly brackets, e.g. transforming `/item/{_id}` to `'/item/'+entry._id`.
    #   If you supply a function, it will be called with the current entry,
    #   the base URL and the resource list url (`config.url`) and should return
    #   a string that will be used as URL.
    # @param {String} [config.baseUrl] Overwrite base URL
    # @param {Bool} [config.is_singleton] Whether resource returns an object
    # @param {Object} [config.storage] Storage implementation, e.g.
    #   `CollectionLocalStorage` (see below)
    # @param {Function} [config.storage.setItem]
    # @param {Function} [config.storage.getItem]
    # @param {Function} [config.storage.removeItem]
    # @param {Function} [config.transformRequest=`_.identity`] Takes the
    #   _request_ `data` and a hint like 'array', 'one', 'save', 'destroy'
    #   and returns the transformed `data`. *NYI*
    # @param {Function} [config.transformResponse=`_.identity`] Takes the
    #   _response_ `data` and a hint like 'array', 'one', 'save', 'destroy'
    #   and returns the transformed `data`.
    # @param {Function} [config.matchingCriteria] Takes data object and returns
    #   matching criteria. Default: `(data) -> id: +data.id`
    # @param {Object} [extras] Add custom methods to instance, functions will
    #   be have `config` as `this`, objects will used to construct new `$http`
    #   calls
    # @return {Object} The collection
    # @throws {Error} When no name is given
    #
    # @example
    # ```coffeescript
    # Collection.new 'User', {
    #   url: '/user' # also set implicitly from name
    #   is_singleton: true # Expect single object instead of array
    #   storage: myStorage # see below
    # }, {
    #   something: (id) -> 42
    #   pay:
    #     method: 'PATCH'
    #     params:
    #       payout: true
    # }
    # ```
    ###
    constructor = (name, config={}, extras={}) ->
      # This will be returned.
      exports = {}

      # ### Options
      throw new Error "No name given!" unless name?

      ###
      # @method Config Getter
      #
      # @description Retrieve config value from instance
      # @param {String} key
      # @return {Any} Config value
      ###
      exports.config = (key) ->
        config[key]

      config.url ||= '/' + name.toLowerCase()
      config.baseUrl ||= globalConfig.baseUrl
      config.listUrl ||= config.url

      ###
      # @method Make Detail URL from Pattern
      #
      # @param {Object} entry The entry to URL points to
      # @param {String} [listUrl=config.url]
      # @param {String} [baseUrl=config.baseUrl]
      # @return {String} Entry URL
      ###
      config.parseUrlPattern = (entry, url) ->
        substitutes = /\{([\w_.]*?)\}/g
        entryUrl = url
        _.each url.match(substitutes), (match) ->
          # Remove braces and split on dots (might address sub-object, e.g.
          # using `item.id`)
          keys = match.replace('{', '').replace('}', '').split('.')
          value = entry
          _.each keys, (key) ->
            value = value[key]

          if value?
            entryUrl = entryUrl.replace match, value
          else
            throw new Error "#{name} Model: Can't substitute #{match} in URL"+
              "(entry has no value for #{key})"

        return entryUrl

      if _.isString config.detailUrl
        makeDetailUrl = (entry) ->
          config.parseUrlPattern(entry, "#{config.baseUrl}#{config.detailUrl}")
      else
        makeDetailUrl = (entry, listUrl=config.listUrl, baseUrl=config.baseUrl) ->
          if entry.id?
            "#{baseUrl}#{listUrl}/#{entry.id}"
          else
            throw new Error "#{name} Model: Need entry ID to construct URL"

      if _.isFunction config.detailUrl
        config.getDetailUrl = (entry, listUrl=config.listUrl, baseUrl=config.baseUrl) ->
          config.detailUrl(entry, listUrl, baseUrl)
      else
        config.getDetailUrl = makeDetailUrl


      IS_SINGLETON = !!config.is_singleton

      config.transformRequest ||= _.identity
      config.transformResponse ||= _.identity

      config.matchingCriteria ||= (data) -> id: +data.id

      # #### Storage Implementation
      ###
      # Use key/value store to persist data.
      #
      # Key schema: "{collection name}.{all|data}"
      #
      # Use any implementation that has these methods:
      #
      # - `setItem(String key, value)`
      # - `getItem(String key)`
      # - `removeItem(String key)`
      #
      # ```coffeescript
      # myStorage =
      #   getItem: (key) ->
      #     value = window.localStorage.getItem(key)
      #     value && JSON.parse(value)
      #   setItem: (key, value) ->
      #     window.localStorage.setItem(key, angular.toJson(value))
      #   removeItem: (key) ->
      #     window.localStorage.removeItem(key)
      #
      # Collection.new 'People', {storage: myStorage} # uses localStorage now
      # ```
      ###
      store = do ->
        _store = {}
        impl = config.storage or {}

        _.each ['setItem', 'getItem', 'removeItem'], (method) ->
          _store[method] = if _.isFunction impl[method]
            impl[method]
          else angular.noop

        _store

      # ### In Memory Data
      ###
      # The Single Source of Truth
      #
      # @private
      ###
      Data = {}

      if IS_SINGLETON # Is single Model
        _data =
          data: store.getItem("#{name}.data") || {}

        ###
        # @method Get Data
        # @return {Object} data
        ###
        Data.get = -> _data.data

        ###
        # @method Replace Singleton Data
        #
        # @param {Object} data New data
        # @return {Object} The complete data representation
        ###
        Data.replace = (data) ->
          _data.data = _.extend(_data.data, data)
          store.setItem("#{name}.data", _data.data)
          return _data.data

      else # is Model[]
        _data =
          all: store.getItem("#{name}.all") || []

        ###
        # @method Get Data
        # @return {Array} data
        ###
        Data.get = -> _data.all

        ###
        # @method Replace Complete Collection Data
        #
        # @param {Array} data New data
        # @return {Object} The complete data representation
        ###
        Data.replace = (data) ->
          _data.all.splice(0, data.length)
          [].push.apply(_data.all, data)
          store.setItem("#{name}.all", _data.all)
          return _data.all

        ###
        # @method Update Single Entry from Collection
        #
        # @description This will also add an entry if no existing one matches
        #   the criteria
        #
        # @param {Object} data New data
        # @param {Object} criteria Used to find entry
        # @return {Object} The updated entry
        ###
        Data.updateEntry = (data, criteria) ->
          hit = _.findWhere(_data.all, criteria)
          if hit?
            # update existing entry
            hit = _.extend(hit, data)
          else
            # add new entry (on top of list)
            _data.all.unshift(data)

          store.setItem("#{name}.all", _data.all)

          return if hit? then hit else data

        ###
        # @method Remove Single Entry from Collection
        #
        # @param {Object} criteria Used to find entry
        # @return {Bool} Whether removal was
        ###
        Data.removeEntry = (criteria) ->
          hit = _.findWhere(_data.all, criteria)
          if hit?
            _data.all.splice _data.all.indexOf(hit), 1
            store.removeItem("#{name}.all", _data.all)
          return hit?

      config.Data = exports.Data = Data

      # ### HTTP Requests and Stuff

      ###
      # @method Retrieve List
      #
      # @description Gotta catch 'em all!
      #
      # @param {Object} [options] HTTP options
      # @return {Promise} HTTP data
      ###
      exports.fetchAll = (options={}) ->
        httpOptions = _.defaults options,
          method: "GET"
          url: "#{config.baseUrl}#{config.url}"

        $http(httpOptions)
        .then (response) ->
          unless _.isArray(response.data)
            console.warn "#{name} Model", "API Respsonse was", response.data
            throw new Error "#{name} Model: Expected array, got #{typeof response.data}"

          response.data = config.transformResponse(response.data, 'array')

          # replace array items with new data
          response.data = Data.replace(response.data)

          return $q.when(response)

      ###
      # @method Retrieve Singleton
      #
      # @param {Object} [options] HTTP options
      # @return {Promise} HTTP data
      ###
      exports.fetch = (options={}) ->
        httpOptions = _.defaults options,
          method: "GET"
          url: "#{config.baseUrl}#{config.url}"

        $http(httpOptions)
        .then (response) ->
          unless _.isObject(response.data)
            console.warn "#{name} Model", "API Respsonse was", response.data
            throw new Error "#{name} Model: Expected object, got #{typeof response.data}"

          response.data = config.transformResponse(response.data, 'one')
          response.data = Data.replace(response.data)
          return $q.when(response)

      ###
      # @method Retrieve One
      #
      # @description This also updates the internal data collection, of course.
      #
      # @param {String} id The ID of the element to fetch.
      # @param {Object} [options] HTTP options
      # @return {Promise} HTTP data
      #
      # @todo Customize ID query
      ###
      exports.fetchOne = (query, options={}) ->
        try
          _url = config.getDetailUrl(query, config.listUrl, config.baseUrl)
        catch e
          return $q.reject e.message || e

        httpOptions = _.defaults options,
          method: "GET"
          url: _url

        $http(httpOptions)
        .then (res) ->
          unless _.isObject(res.data)
            console.warn "#{name} Model", "API Respsonse was", res.data
            throw new Error "Expected object, got #{typeof res.data}"

          res.data = config.transformResponse(res.data, 'one')
          res.data = Data.updateEntry res.data, config.matchingCriteria(res.data)
          return $q.when(res)

      ###
      # @method Destroy some Entry
      #
      # @param {String} id The ID of the element to fetch.
      # @param {Object} [options] HTTP options
      # @return {Promise} Whether destruction was successful
      # @throws {Error} When Collection is singleton or no ID is given
      #
      # @todo Customize ID query
      ###
      exports.destroy = (query, options={}) ->
        if IS_SINGLETON
          throw new Error "#{name} Model: Singleton doesn't have `destroy` method."

        try
          _url = config.getDetailUrl(query, config.listUrl, config.baseUrl)
        catch e
          return $q.reject e.message || e

        httpOptions = _.defaults options,
          method: "DELETE"
          url: _url

        $http(httpOptions)
        .then ({status, data}) ->
          data = config.transformResponse(data, 'destroy')
          return $q.when Data.removeEntry config.matchingCriteria(data)

      ###
      # @method Save an Entry
      #
      # @param {Object} entry The entry to be saved.
      # @param {Object} [options] HTTP options
      # @return {Promise} Resolved with new entry or rejected with HTTP error
      #
      # @todo Customize ID query
      ###
      exports.save = (entry, options={}) ->
        if IS_SINGLETON
          _url = "#{config.baseUrl}#{config.listUrl}"
        else
          try
            _url = config.getDetailUrl(entry, config.listUrl, config.baseUrl)
          catch e
            return $q.reject e.message || e

        httpOptions = _.defaults options,
          method: "PUT"
          url: _url
          data: angular.toJson(entry)

        return $http(httpOptions)
        .then ({status, data}) ->
          data = config.transformResponse(data, 'save')

          if IS_SINGLETON
            return $q.when Data.replace(data)
          else
            return $q.when Data.updateEntry data, config.matchingCriteria(data)

      ###
      # @method Create an Entry
      #
      # @description Similar to save, but has no ID initially.
      #
      # @param {Object} entry Entry data
      # @param {Object} [options] HTTP options
      # @return {Promise} Resolves with new entry data or rejects with HTTP error
      # @throws {Error} When Collection is singleton
      ###
      exports.create = (entry, options={}) ->
        if IS_SINGLETON
          throw new Error "#{name} Model: Singleton doesn't have `destroy` method."

        httpOptions = _.defaults options,
          method: "POST"
          url: "#{config.baseUrl}#{config.listUrl}"
          data: angular.toJson(entry)

        return $http(httpOptions)
        .then ({status, data}) ->
          return $q.when Data.updateEntry data, config.matchingCriteria(data)

      # - - -

      # ### Generic Getters

      ###
      # @method Get Collection
      #
      # @param {Object} [options] HTTP options
      # @return {Object} Immediate Return Data (see above)
      ###
      exports.all = (options) ->
        local =
          $loading: true

        if IS_SINGLETON
          local.$promise = exports.fetch(options)
          local.data = _data.data
        else
          local.$promise = exports.fetchAll(options)
          local.all = _data.all

        local.$promise = local.$promise
        .then (response) ->
          local.$loading = false
          local.$resolved = true
          $q.when(response)
        .then null, (err) ->
          local.$error = err
          local.$loading = false
          $q.reject(err)

        return local

      ###
      # @method Query Collection
      #
      # @param {Object} query Query the collection á la `{name: "Jim"}`
      # @return {Array} Objects matching the query.
      ###
      exports.where = (query) ->
        _.where(_data.all, query)

      ###
      # @method Get Single Collection Entry
      #
      # @param {Object} query The query that will be used in `matchingCriteria`
      # @param {Object} [options] HTTP options
      # @return {Object} Immediate Return Data (see above)
      # @throws {Error} When Collection is singleton
      #
      # @todo Customize ID query
      ###
      exports.get = (query, options) ->
        if IS_SINGLETON
          throw new Error "#{name} Model: Singleton doesn't have `get` method."

        local =
          $loading: true

        local.data = _.findWhere _data.all, config.matchingCriteria(query)
        local.$promise = exports.fetchOne(query, options)
        .then (response) ->
          local.data = response.data
          local.$loading = false
          local.$resolved = true
          $q.when(response)
        .then null, (err) ->
          local.$error = err
          local.$loading = false
          $q.reject(err)

        return local

      # ### Mixin Extras

      addExtraCall = (key, val) ->
        unless val.url
          val.url = "#{config.baseUrl}#{config.listUrl}/#{key}"

        if _.isFunction val.onSuccess
          success = _.bind(val.onSuccess, config)
          delete val.onSuccess
        if _.isFunction val.onFail
          fail = _.bind(val.onFail, config)
          delete val.onFail

        # @todo Add data storage options
        exports[key] = (data, options={}) ->
          if !options.url
            if _.isFunction(val.url)
              options.url = val.url(data, config.listUrl, config.detailUrl)
            else
              options.url = config.parseUrlPattern(data, "#{config.baseUrl}#{val.url}")

          call = $http _.defaults(options, val), data
          call.then(success) if success?
          call.then(null, fail) if fail?
          return call

      _.each extras, (val, key) ->
        # Custom methods
        if _.isFunction(val)
          exports[key] = _.bind(val, config)
        # Custom HTTP Call
        else if _.isObject(val)
          addExtraCall key, val


      # - - -
      exports

    return new: constructor

  return


.factory "CollectionLocalStorage", ->
  # ## Storage Wrapper for LocalStorage
  return unless window.localStorage?

  return {
    # ### Get Item
    ###
    # @param {String} key
    # @return {Any}
    ###
    getItem: (key) ->
      value = window.localStorage.getItem(key)
      value && JSON.parse(value)

    # ### Set Item
    ###
    # @param {String} key
    # @param {Any} value
    # @return {Any}
    ###
    setItem: (key, value) ->
      window.localStorage.setItem(key, angular.toJson(value))

    # ### Remove Item
    ###
    # @param {String} key
    ###
    removeItem: (key) ->
      window.localStorage.removeItem(key)
  }
