/*!
* angular-epicmodel
*
* @author [Pascal Hertleif](https://github.com/killercup)
* @version 0.3.4
* @license MIT
*/
(function () {
  angular.module('EpicModel', []).provider('Collection', function () {
    var globalConfig;
    globalConfig = { baseUrl: '' };
    this.setBaseUrl = function (url) {
      if (url == null) {
        url = '';
      }
      if (url == null) {
        throw new Error('No URL given.');
      }
      return globalConfig.baseUrl = url;
    };
    this.$get = [
      '$q',
      '$http',
      function ($q, $http) {
        var constructor;
        constructor = function (name, config, extras) {
          var Data, IS_SINGLETON, addExtraCall, exports, makeDetailUrl, store, _data;
          if (config == null) {
            config = {};
          }
          if (extras == null) {
            extras = {};
          }
          exports = {};
          if (name == null) {
            throw new Error('No name given!');
          }
          exports.config = function (key) {
            return config[key];
          };
          config.url || (config.url = '/' + name.toLowerCase());
          config.baseUrl || (config.baseUrl = globalConfig.baseUrl);
          config.listUrl || (config.listUrl = config.url);
          config.parseUrlPattern = function (entry, url) {
            var entryUrl, substitutes;
            substitutes = /\{([\w_.]*?)\}/g;
            entryUrl = url;
            _.each(url.match(substitutes), function (match) {
              var keys, value;
              keys = match.replace('{', '').replace('}', '').split('.');
              value = entry;
              _.each(keys, function (key) {
                return value = value[key];
              });
              if (value != null) {
                return entryUrl = entryUrl.replace(match, value);
              } else {
                throw new Error('' + name + ' Model: Can\'t substitute ' + match + ' in URL' + ('(entry has no value for ' + key + ')'));
              }
            });
            return entryUrl;
          };
          if (_.isString(config.detailUrl)) {
            makeDetailUrl = function (entry) {
              return config.parseUrlPattern(entry, config.detailUrl);
            };
          } else {
            makeDetailUrl = function (entry, listUrl, baseUrl) {
              if (listUrl == null) {
                listUrl = config.listUrl;
              }
              if (baseUrl == null) {
                baseUrl = config.baseUrl;
              }
              if (entry.id != null) {
                return '' + baseUrl + listUrl + '/' + entry.id;
              } else {
                throw new Error('' + name + ' Model: Need entry ID to construct URL');
              }
            };
          }
          if (_.isFunction(config.detailUrl)) {
            config.getDetailUrl = function (entry, listUrl, baseUrl) {
              if (listUrl == null) {
                listUrl = config.listUrl;
              }
              if (baseUrl == null) {
                baseUrl = config.baseUrl;
              }
              return config.detailUrl(entry, listUrl, baseUrl);
            };
          } else {
            config.getDetailUrl = makeDetailUrl;
          }
          IS_SINGLETON = !!config.is_singleton;
          config.transformRequest || (config.transformRequest = _.identity);
          config.transformResponse || (config.transformResponse = _.identity);
          config.matchingCriteria || (config.matchingCriteria = function (data) {
            return { id: +data.id };
          });
          store = function () {
            var impl, _store;
            _store = {};
            impl = config.storage || {};
            _.each([
              'setItem',
              'getItem',
              'removeItem'
            ], function (method) {
              return _store[method] = _.isFunction(impl[method]) ? impl[method] : angular.noop;
            });
            return _store;
          }();
          Data = {};
          if (IS_SINGLETON) {
            _data = { data: store.getItem('' + name + '.data') || {} };
            Data.get = function () {
              return _data.data;
            };
            Data.replace = function (data) {
              _data.data = _.extend(_data.data, data);
              store.setItem('' + name + '.data', _data.data);
              return _data.data;
            };
          } else {
            _data = { all: store.getItem('' + name + '.all') || [] };
            Data.get = function () {
              return _data.all;
            };
            Data.replace = function (data) {
              _data.all.splice(0, data.length);
              [].push.apply(_data.all, data);
              store.setItem('' + name + '.all', _data.all);
              return _data.all;
            };
            Data.updateEntry = function (data, criteria) {
              var hit;
              hit = _.findWhere(_data.all, criteria);
              if (hit != null) {
                hit = _.extend(hit, data);
              } else {
                _data.all.unshift(data);
              }
              store.setItem('' + name + '.all', _data.all);
              if (hit != null) {
                return hit;
              } else {
                return data;
              }
            };
            Data.removeEntry = function (criteria) {
              var hit;
              hit = _.findWhere(_data.all, criteria);
              if (hit != null) {
                _data.all.splice(_data.all.indexOf(hit), 1);
                store.removeItem('' + name + '.all', _data.all);
              }
              return hit != null;
            };
          }
          config.Data = exports.Data = Data;
          exports.fetchAll = function (options) {
            if (options == null) {
              options = {};
            }
            return $http.get('' + config.baseUrl + config.url, options).then(function (response) {
              if (!_.isArray(response.data)) {
                console.warn('' + name + ' Model', 'API Respsonse was', response.data);
                throw new Error('' + name + ' Model: Expected array, got ' + typeof response.data);
              }
              response.data = config.transformResponse(response.data, 'array');
              response.data = Data.replace(response.data);
              return $q.when(response);
            });
          };
          exports.fetch = function (options) {
            if (options == null) {
              options = {};
            }
            return $http.get('' + config.baseUrl + config.url, options).then(function (response) {
              if (!_.isObject(response.data)) {
                console.warn('' + name + ' Model', 'API Respsonse was', response.data);
                throw new Error('' + name + ' Model: Expected object, got ' + typeof response.data);
              }
              response.data = config.transformResponse(response.data, 'one');
              response.data = Data.replace(response.data);
              return $q.when(response);
            });
          };
          exports.fetchOne = function (query, options) {
            var e, _url;
            if (options == null) {
              options = {};
            }
            try {
              _url = config.getDetailUrl(query, config.listUrl, config.baseUrl);
            } catch (_error) {
              e = _error;
              return $q.reject(e.message || e);
            }
            return $http.get(_url, options).then(function (res) {
              if (!_.isObject(res.data)) {
                console.warn('' + name + ' Model', 'API Respsonse was', res.data);
                throw new Error('Expected object, got ' + typeof res.data);
              }
              res.data = config.transformResponse(res.data, 'one');
              res.data = Data.updateEntry(res.data, config.matchingCriteria(res.data));
              return $q.when(res);
            });
          };
          exports.destroy = function (query, options) {
            var e, _url;
            if (options == null) {
              options = {};
            }
            if (IS_SINGLETON) {
              throw new Error('' + name + ' Model: Singleton doesn\'t have `destroy` method.');
            }
            try {
              _url = config.getDetailUrl(query, config.listUrl, config.baseUrl);
            } catch (_error) {
              e = _error;
              return $q.reject(e.message || e);
            }
            return $http['delete'](_url, options).then(function (_arg) {
              var data, status;
              status = _arg.status, data = _arg.data;
              data = config.transformResponse(data, 'destroy');
              return $q.when(Data.removeEntry(data, config.matchingCriteria(data)));
            });
          };
          exports.save = function (entry, options) {
            var e, _url;
            if (options == null) {
              options = {};
            }
            if (IS_SINGLETON) {
              _url = '' + config.baseUrl + config.listUrl;
            } else {
              try {
                _url = config.getDetailUrl(entry, config.listUrl, config.baseUrl);
              } catch (_error) {
                e = _error;
                return $q.reject(e.message || e);
              }
            }
            return $http.post(_url, JSON.stringify(entry), options).then(function (_arg) {
              var data, status;
              status = _arg.status, data = _arg.data;
              data = config.transformResponse(data, 'save');
              if (IS_SINGLETON) {
                return $q.when(Data.replace(data));
              } else {
                return $q.when(Data.updateEntry(data, config.matchingCriteria(data)));
              }
            });
          };
          exports.create = function (entry, options) {
            if (options == null) {
              options = {};
            }
            if (IS_SINGLETON) {
              throw new Error('' + name + ' Model: Singleton doesn\'t have `destroy` method.');
            }
            return $http.post('' + config.baseUrl + config.listUrl, entry, options).then(function (_arg) {
              var data, status;
              status = _arg.status, data = _arg.data;
              return $q.when(Data.updateEntry(data, config.matchingCriteria(data)));
            });
          };
          exports.all = function (options) {
            var local;
            local = { $loading: true };
            if (IS_SINGLETON) {
              local.$promise = exports.fetch(options);
              local.$promise.then(function () {
                local.$loading = false;
                return local.$resolved = true;
              });
              local.data = _data.data;
            } else {
              local.$promise = exports.fetchAll(options);
              local.$promise.then(function () {
                local.$loading = false;
                return local.$resolved = true;
              });
              local.all = _data.all;
            }
            return local;
          };
          exports.where = function (query) {
            return _.where(_data.all, query);
          };
          exports.get = function (query, options) {
            var local;
            if (IS_SINGLETON) {
              throw new Error('' + name + ' Model: Singleton doesn\'t have `get` method.');
            }
            local = { $loading: true };
            local.data = _.findWhere(_data.all, config.matchingCriteria(query));
            local.$promise = exports.fetchOne(query, options).then(function (response) {
              local.data = response.data;
              local.$loading = false;
              local.$resolved = true;
              return $q.when(response);
            });
            return local;
          };
          addExtraCall = function (key, val) {
            var fail, success;
            if (!val.url) {
              val.url = '' + config.baseUrl + config.listUrl + '/' + key;
            }
            if (_.isFunction(val.onSuccess)) {
              success = _.bind(val.onSuccess, config);
              delete val.onSuccess;
            }
            if (_.isFunction(val.onFail)) {
              fail = _.bind(val.onFail, config);
              delete val.onFail;
            }
            return exports[key] = function (data, options) {
              var call;
              if (options == null) {
                options = {};
              }
              if (!options.url) {
                if (_.isFunction(val.url)) {
                  options.url = val.url(data, config.listUrl, config.detailUrl);
                } else {
                  options.url = config.parseUrlPattern(data, val.url);
                }
              }
              call = $http(_.extend(val, options), data);
              if (success != null) {
                call.then(success);
              }
              if (fail != null) {
                call.then(null, fail);
              }
              return call;
            };
          };
          _.each(extras, function (val, key) {
            if (_.isFunction(val)) {
              return exports[key] = _.bind(val, config);
            } else if (_.isObject(val)) {
              return addExtraCall(key, val);
            }
          });
          return exports;
        };
        return { 'new': constructor };
      }
    ];
  }).factory('CollectionLocalStorage', function () {
    if (window.localStorage == null) {
      return;
    }
    return {
      getItem: function (key) {
        var value;
        value = window.localStorage.getItem(key);
        return value && JSON.parse(value);
      },
      setItem: function (key, value) {
        return window.localStorage.setItem(key, JSON.stringify(value));
      },
      removeItem: function (key) {
        return window.localStorage.removeItem(key);
      }
    };
  });
}.call(this));