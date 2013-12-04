# EpicModel

A model/collection service for Angular.js

Inspired by [$resource](http://docs.angularjs.org/api/ngResource.$resource), I wanted to create a service that can manage the data retrieved from an API and always return the same objects, so Angular will automatically update all your views.

```coffeescript
Messages = Collection.new "Messages", url: "/messages"

Messages.all()
# => {all: Array(), $promise: {then, finally, catch}}

Messages.get(id: 42)
# => {data: Object(), $promise: {then, finally, catch}}
```

[![Build Status](https://travis-ci.org/killercup/angular-epicmodel.png?branch=master)](https://travis-ci.org/killercup/angular-epicmodel)

## Install

For now, just make sure the `src/model.coffee` is somewhere in your build process so you can require `EpicModel` in your modules.

### Dependencies

- Underscore/Lodash

## Usage

You should read the inline documentation for `src/model.coffee`. It's quite comprehensive and full of examples.

## Features

- [x] Retrieve single object resource (e.g. `/users/me`)
- [x] Retrieve list resources and manage them in an array structure
- [x] Update list resources after retrieving matching single resource
- [x] Add custom sub-resources (e.g. `/users/$id/follow` as `User.follow(id)`)
- [x] Incremental updates (á la `/messages?since=1386150532`, see `extras_spec`)
- [ ] Transform requests
- [x] Transform response
- [x] Customizable URL patterns (always uses `$url/$id` for now, but should also offer stuff like `/item/{item._id}/property/{_id}`)
- [x] Persistent storage wrapper (save to storage, retrieve when initializing)
- [x] Implemented `localStorage` wrapper

