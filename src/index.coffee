'use strict'

path = require 'path'
_ = require 'lodash'
streamHasher = require 'stream-hasher'
streamReplacer = require 'stream-replacer'
extractor = require './extractor'
mapper = require './mapper'
resolver = require './resolver'


class Crusher
  constructor: (options) ->
    @resolver = resolver timeout: 1000
    @extractor = extractor base: '/app'
    @mapper = mapper options.counterparts

  pusher: ->
    crusher = @
    streamHasher
      digestLength: 8
      rename: (name, digest) -> "#{name}-#{digest}"
    .on 'rename', (oldTag, newTag) ->
      oldUrl = crusher.mapper.map oldTag
      newUrl = crusher.mapper.map newTag
      # console.log 'rename %s -> %s', oldUrl, newUrl
      crusher.resolver.push oldUrl, null, newUrl

  puller: ->
    crusher = @
    streamReplacer
      pattern: crusher.extractor.getPattern()
      substitute: (match, tag, done) ->
        parts = crusher.extractor.split match
        # console.log 'parts=', parts
        crusher.resolver.pull parts.path, (err, newPath) ->
          if err
            done err
            return
          replacement = parts.preamble + newPath + parts.postamble
          done null, replacement
          return


factory = (options) ->
  new Crusher options

factory.Crusher = Crusher

module.exports = factory
