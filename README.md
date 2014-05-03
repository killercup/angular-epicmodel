# EpicModel

Easily query and update your JSON API using `angular.js`.

Inspired by [ngResource](http://docs.angularjs.org/api/ngResource.$resource), I wanted to create a service that can manage the data retrieved from an API and always return the same objects, so Angular will automatically update all your views.

```js
var Messages = Collection.new("Messages", {url: "/messages"});

Messages.all()
// => {Array all, $promise: {Function then}, ...}

Messages.get({id: 42})
// => {Object data, $promise: {Function then}, ...}
```

[![Build Status](https://travis-ci.org/killercup/angular-epicmodel.svg?branch=master)](https://travis-ci.org/killercup/angular-epicmodel)

## Installation

Grab the source code, e.g. by using [bower](http://bower.io/), which will fetch the latest release tag and all dependencies:

```sh
$ bower install killercup/angular-epicmodel
```

Include all dependencies and EpicModel in your build process or HTML file. (Choose one of `dist/model.js`, `dist/model.min.js` or `src/model.coffee`.)

Add EpicModel as a dependency to the angular modules that use it:

```js
angular.module('DemoApp', ['EpicModel'])
.run(function (Collection) {
  console.log("Did we load EpicModel?", !!Collection);
});
```

### Dependencies

- Angular.js (~1.2)
- [Lodash](http://lodash.com/) (~2.4)

## Usage

I'll try to document as much of the Collection API as possible, but if you want to know what _really_ happens, you should read the (well-documented) source code in `src/model.coffee`. Additionally, the tests may give you a nice overview of some the possibilities.

1. [Creating a Collection Instance](#creating-a-collection-instance)
  1. [Collection Options](#collection-options)
2. [Using API Data](#using-api-data)
3. [Adding Additional API Methods to a Collection](#adding-additional-a-p-i-methods-to-a-collection)
  1. [Add a Method](#add-a-static-method)
  2. [Add a HTTP Call](#add-a-new-h-t-t-p-call)
4. [URL Formatting](#url-formatting)
5. [Global Configuration](#global-configuration)

### Creating a Collection Instance

To describe an API endpoint, you instantiate a new instance of a `Collection` using the `new` method. (Please note, that you might want to call it using `Collection['new']` if you need to support ECMAScript 3 in old browsers.)

Options:

- _name_ (string) for the collection. The URL may be derived from this (e.g. a collection called "Users" has the default URL "/users").
- A _config_ object with options like `url`, `detailUrl` and _is_singleton_ (more info [see below](#collection-options))
- An _extras_ object for additional API methods (for more info [see below](#adding-additional-a-p-i-methods-to-a-collection))

#### Collection Options

This option can be set when creating a collection:

- _url_ (string or function): The URL for the list resources (e.g. `/users`)
- _detailUrl_ (string or function): The URL for the detail resources (e.g. `/users/42`). Default is `[list_url]/[entry.id]`. See [URL Formatting](#url-formatting) for information on how to change this.
- _baseUrl_ (string) to overwrite the global API base URL
- _is_singleton_ (boolean): Set to true when the resource is not a list of entries, but just a single data point, e.g. "/me" (as an alias for requesting the current user).
- _matchingCriteria_ (function): Specify how to match entries (e.g. to update an old representation). The default is to use `entry.id`. If you specify you own function, it should return an object that can be used in lodash's [`where`](http://lodash.com/docs#where) method.
  E.g., to use MongoDB's `_id` field as an identifier, use this a a matching function: `function (item) {return {_id: item._id};}`

### Using API Data

Each Collection instance has the default CRUD methods available as `all()`, `get({id})`, `create(data)`, `update({id}, data)` and `destroy({id})`.

Whereas `create`, `update` and `destroy` return promises, `all` and `get` return objects with special keys so they can be used directly in your view.

```js
var Posts = Collection.new("Posts");

var posts = Posts.all();
// => {
//   all: undefined,
//   $promise: {then()},
//   $loading: true,
//   $resolved: false,
//   $error: false
// }
```

As you can see, the actual data is stored in the `all` property (or `data` for `get` and other calls). Your typical view would look like this:

```html
<p ng-show="posts.$loading">Loading</p>
<p ng-show="posts.$error">Oh noes!</p>
<ul ng-repeat="post in posts.all">
  <li>{{post.title}}</li>
</ul>
```

When API response is received, it will be used to update that object's properties, so that angular's dirty checking can detect a change and update your view automatically.

This has several advantages. Since EpicModel stores all API data in an internal cache, it can set the `posts.all` value to all the posts it has already cached initially. When the new list of posts is received, it can then update the internal cache, adding new entries and updating existing ones. These updates will immediately be reflected in your view.

Even better: Since the objects themselves are always the same ones, even if you have several views displayed each showing a filtered list of posts from this Collection, they will all be updated. You don't even have to use [`track by`][ngRepeat] in your `ng-repeat`!

[ngRepeat]: https://docs.angularjs.org/api/ng/directive/ngRepeat

### Adding Additional API Methods to a Collection

To add more methods to your collection, specify them as keys of the _extras_ object when creating the collection. Their values can either be functions or objects.

Below, three different variants will be shown. For more information (e.g. `onSuccess` or `onFail` transforms), have a look at the [extras tests] or the [extras implementation].

[extras test]: https://github.com/killercup/angular-epicmodel/blob/e85647d287610b7529f1bd7180ba54dacf7255bc/test/unit/extras_spec.coffee
[extras implementation]: https://github.com/killercup/angular-epicmodel/blob/e85647d287610b7529f1bd7180ba54dacf7255bc/src/model.coffee#L552

#### Add a Static Method

The easiest case: Each extras property that is a function will become static method of your collection.

```js
var options = {};
var extras = {
  isNew: function (msg) {
    return true;
  }
};

var messages = Collection.new("Messages", options, extras);

messages.isNew({id: 21})
// => true
```

To make methods more powerful, they are bound to the collection configuration, i.e. `this` in your method will be the object with all configuration options set during the collection creation.

Please note that some helpful methods not documented in the configuration section above are also part of this object, e.g. `config.getDetailUrl(entry)` and `config.Data = {get(), replace(), updateEntry(), removeEntry()}`.

#### Add a New HTTP Call

You could use static methods to make HTTP calls, but EpicModel offers an easier alternative: Just specify an object with HTTP options.

```js
var options = {};
var extras = {
  markUnread: {
    method: 'PUT',
    url: '/messages/{id}/mark_unread',
    params: {
      skip_return: true
    },
    data: {
      'read': false
    }
  }
};

var messages = Collection.new("Messages", options, extras);

var message = {id: 42};
var httpCall = messages.markUnread(message);
// => PUT /messages/42/mark_unread?skip_return=true

httpCall
.then(function (response) {
  console.log(response.data.read);
  // => false
})
.then(null, function (error) {
  console.log(error.status);
  // => e.g. 404
})
```

The only option you need to set is the HTTP method using `method`. If the URL cannot be guessed from the property key, you can overwrite it using `url` (cf. [URL Formatting](#url-formatting)). Additionally, you can specify all the options [$http] can process.

Calling a method specified like this will return a promise that settles with the HTTP response, just like using [$http].

[$http]: https://docs.angularjs.org/api/ng/service/$http#usage

### URL Formatting

One of the clever things in EpicModel is how it allows you to set detail URLs.

When you specify a URL as a string, you can use curly braces to include some values from the entry you are requesting, e.g. `/users/{id}-{name.first}_{name.last}`.

When you specify a function, it will be called with the information about the entry you are requesting, the API's base URL and the list URL (from `config.url`). It should return string.

### Global Configuration

You can inject the `CollectionProvider` into your module's `config` to set the following options:

- API Base URL (string)

```js
angular.module('app', ['EpicModel'])
.config(function (CollectionProvider) {
  CollectionProvider.setBaseUrl("http://localhost:3000");
});
```

## License

MIT
