'use strict'

path = require 'path'
_ = require 'lodash'
streamHasher = require 'stream-hasher'
streamReplacer = require 'stream-replacer'
crushExtractor = require './extractor'
crushMapper = require './mapper'
crushResolver = require './resolver'


class Crusher
  constructor: (options) ->
    @resolver = crushResolver timeout: 1000
    @extractor = crushExtractor base: '/app/'
    @mapper = crushMapper options.counterparts
    root = options.root or '/'
    @tagger = (file) -> path.relative root, file.path

  pushOptioner: (file) ->
    digestLength: 8
    rename: 'postfix'

  pullOptioner: (file) ->
    resolver = @resolver
    extractor = @extractor
    mapper = @mapper
    # console.log 'pattern=', extractor.getPattern()
    pattern: extractor.getPattern()
    substitute: (match, tag, done) ->
      parts = extractor.split match
      # console.log 'parts=', parts
      fsPath = mapper.toFsPath parts.path
      if not fsPath?
        done new Error "no fs-path for url-path '#{parts.path}'"
        return
      resolver.pull fsPath, (err, result) ->
        if err
          done err
          return
        newUrlPath = mapper.toUrlPath result.tag
        if not newUrlPath?
          done new Error "no url-path for url-path '#{result.tag}'"
          return
        replacement = parts.preamble + newUrlPath + parts.postamble
        done null, replacement
        return

  pusher: ->
    resolver = @resolver
    streamHasher
      tagger: @tagger
      optioner: @pushOptioner.bind @
    .on 'digest', (digest, oldTag, newTag) ->
      resolver.push oldTag, null, digest: digest, tag: newTag

  puller: ->
    streamReplacer
      tagger: @tagger
      optioner: @pullOptioner.bind @


factory = (options) ->
  new Crusher options

factory.Crusher = Crusher

module.exports = factory
