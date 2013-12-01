# EpicModel

A model/collection service for Angular.js

Inspired by [$resource](http://docs.angularjs.org/api/ngResource.$resource), I wanted to create a service that can manage the data retrieved from an API and always return the same objects, so Angular will automatically update all your views.

## Install

For now, just make sure the `src/model.coffee` is somewhere in your build process so you can require `EpicModel` in your modules.

### Dependencies

- Underscore/Lodash

## Usage

You should read the documentation for `src/model.coffee`.

## Features

- [x] Retrieve single object resource (e.g. `/users/me`)
- [x] Retrieve list resources and manage them in an array structure
- [x] Update list resources after retrieving matching single resource
- [ ] Add custom sub-resources (e.g. `/users/$id/follow` as `User.follow(id)`)

- [ ] Transform requests
- [x] Transform response
- [ ] Customizable URL patterns (always uses `$url/$id` for now)

- [x] Persistent storage wrapper (save to storage, retrieve when initializing)
- [x] Implemented `localStorage` wrapper

