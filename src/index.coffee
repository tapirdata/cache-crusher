'use strict'

path = require 'path'
_ = require 'lodash'
streamHasher = require 'stream-hasher'
streamReplacer = require 'stream-replacer'
crushMapper = require './mapper'
crushResolver = require './resolver'
crushExtractorCatalog = require './extractor-catalog'


class Crusher
 
  @defaultResolverOptions:
    timeout: 1000

  @defaultMapperOptions: {}

  constructor: (options) ->
    options = options or {}
    resolverOptions = _.merge {}, @constructor.defaultResolverOptions, options.resolver
    mapperOptions = _.merge {}, @constructor.defaultMapperOptions, options.mapper
    @resolver = crushResolver resolverOptions
    @mapper = crushMapper mapperOptions
    root = options.root or '/'
    @tagger = (file) -> path.relative root, file.path
    @extractorCatalog = options.extractorCatalog or crushExtractorCatalog()

  getExtractor: (file) ->
    ext = path.extname file.path
    handle = @extractorCatalog.getHandle ext
    Extractor = @extractorCatalog.getClass handle
    if Extractor?
      new Extractor base: '/app/'

  pushOptioner: (options, file) ->
    digestLength: 8
    rename: 'postfix'

  pullOptioner: (options, file) ->
    resolver = @resolver
    mapper = @mapper
    extractor = @getExtractor file
    if not extractor
      console.warn "no extractor for file '#{file.path}'"
      return pattern: null
    pattern: extractor.getPattern()
    substitute: (match, tag, done) ->
      parts = extractor.split match
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

  pusher: (options) ->
    resolver = @resolver
    streamHasher
      tagger: @tagger
      optioner: @pushOptioner.bind @, options
    .on 'digest', (digest, oldTag, newTag) ->
      resolver.push oldTag, null, digest: digest, tag: newTag

  puller: (options) ->
    streamReplacer
      tagger: @tagger
      optioner: @pullOptioner.bind @, options


factory = (options) ->
  new Crusher options

factory.Crusher = Crusher

module.exports = factory
