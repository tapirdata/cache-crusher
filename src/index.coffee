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
      rename: 'postfix'
    .on 'digest', (digest, oldTag, newTag) ->
      crusher.resolver.push oldTag, null, digest: digest, tag: newTag

  puller: ->
    crusher = @
    streamReplacer
      pattern: crusher.extractor.getPattern()
      substitute: (match, tag, done) ->
        parts = crusher.extractor.split match
        fsPath = crusher.mapper.toFsPath parts.path
        if not fsPath?
          done new Error "no fs-path for url-path '#{parts.path}'"
          return
        crusher.resolver.pull fsPath, (err, result) ->
          if err
            done err
            return
          newUrlPath = crusher.mapper.toUrlPath result.tag
          if not newUrlPath?
            done new Error "no url-path for url-path '#{result.tag}'"
            return
          replacement = parts.preamble + newUrlPath + parts.postamble
          done null, replacement
          return


factory = (options) ->
  new Crusher options

factory.Crusher = Crusher

module.exports = factory
