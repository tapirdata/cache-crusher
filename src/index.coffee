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

  @defaultExtractorOptions:
    urlBase: '/static/'

  constructor: (options) ->
    options = options or {}
    resolverOptions = _.merge {}, @constructor.defaultResolverOptions, options.resolver
    mapperOptions = _.merge {}, @constructor.defaultMapperOptions, options.mapper

    @resolver = crushResolver resolverOptions
    @mapper = crushMapper mapperOptions
    @cwd = options.cwd or process.cwd()

    extractorOptions = _.merge {}, @constructor.defaultExtractorOptions, options.extractor
    if not extractorOptions.catalog
      extractorOptions.catalog = crushExtractorCatalog()
    @extractorOptions = extractorOptions

  getTagger: (base) ->
    if base?
      (file) -> path.join base, file.relative
    else
      base = @cwd
      (file) -> path.relative base, file.path

  getExtractor: (file) ->
    ext = path.extname file.path
    catalog = @extractorOptions.catalog
    handle = catalog.getHandle ext
    Extractor = catalog.getClass handle
    if Extractor?
      new Extractor
        base: @extractorOptions.urlBase

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
      console.log 'puller tag=%s', tag
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
    options = options or {}
    resolver = @resolver
    streamHasher
      tagger: @getTagger options.base
      optioner: @pushOptioner.bind @, options
    .on 'digest', (digest, oldTag, newTag) ->
      console.log 'pusher tag=%s', oldTag
      resolver.push oldTag, null, digest: digest, tag: newTag

  puller: (options) ->
    streamReplacer
      tagger: @getTagger()
      optioner: @pullOptioner.bind @, options


factory = (options) ->
  new Crusher options

factory.Crusher = Crusher

module.exports = factory
