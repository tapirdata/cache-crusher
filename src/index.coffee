'use strict'

path = require 'path'
_ = require 'lodash'
stream = require 'readable-stream'
streamHasher = require 'stream-hasher'
streamReplacer = require 'stream-replacer'


class Crusher

  @defaultResolverOptions:
    timeout: 1000

  @defaultMapperOptions: {}

  @defaultExtractorOptions:
    urlBase: '/static/'

  @defaultCrushOptions:
    rename: 'postfix'
    digestLength: 8

  debug: ->

  constructor: (options) ->
    options = options or {}
    @cwd = options.cwd or process.cwd()
    @enabled = options.enabled != false

    resolverOptions = _.merge {}, @constructor.defaultResolverOptions, options.resolver
    @resolver = resolverOptions._ or require('./resolver') resolverOptions

    mapperOptions = _.merge {}, @constructor.defaultMapperOptions, options.mapper
    @mapper = mapperOptions._ or require('./mapper') mapperOptions

    @crushOptions = _.merge {}, @constructor.defaultCrushOptions, options.crush

    extractorOptions = _.merge {}, @constructor.defaultExtractorOptions, options.extractor
    if not extractorOptions.catalog
      extractorOptions.catalog = require('./extractor-catalog')()
    @extractorOptions = extractorOptions

    debug = options.debug
    if debug
      if typeof debug != 'function'
        debug = console.error
      @debug = debug

  getTagger: (base) ->
    if base?
      (file) -> path.join base, file.relative
    else
      cwd = @cwd
      (file) -> path.relative cwd, file.path

  getExtractor: (file) ->
    ext = path.extname file.path
    catalog = @extractorOptions.catalog
    handle = catalog.getHandle ext
    Extractor = catalog.getClass handle
    if Extractor?
      new Extractor
        base: @extractorOptions.urlBase

  _getCrushOptions: (entry) ->
    crushOptions = @crushOptions
    if entry.crushOptions
      crushOptions = _.merge {}, crushOptions, entry.crushOptions
    crushOptions

  pushOptioner: (tagger, options, file) ->
    tag = tagger file
    mapper = @mapper
    map = mapper.getTagMap tag
    @debug 'pushOptioner tag=%s map.entry=%s', tag, map.entry
    if not map.entry?
      return {}
    @_getCrushOptions map.entry

  pullOptioner: (options, file) ->
    self = @
    extractor = @getExtractor file
    if not extractor
      console.warn "no extractor for file '#{file.path}'"
      return pattern: null
    pattern: extractor.getPattern()
    substitute: (match, originTag, done) ->
      self.debug 'puller originTag=%s', originTag
      parts = extractor.split match
      map = self.mapper.getUrlMap parts.path
      self.debug 'substitute: url=%s map=%s', parts.path, map
      if not map.entry?
        done()
        return
      self.resolver.pull map.entry.getTag(map.rel), originTag, (err, result) ->
        if err
          done err
          return
        if result.tag?
          newUrl = map.entry.getUrl map.entry.getTagRel result.tag
          self.debug 'substitute: newUrl=%s', newUrl, parts
          replacement = parts.preamble + newUrl + parts.query + parts.postamble
        else
          crushOptions = self._getCrushOptions map.entry
          if crushOptions?
            append = crushOptions.append
            if append?
              newQuery = parts.query
              if newQuery
                newQuery += '&'
              else
                newQuery += '?'
              if _.isFunction append
                rev = append result.digest
              else if _.isString append
                rev = append + '=' + result.digest
              else
                rev = result.digest
              newQuery += rev
              replacement = parts.preamble + parts.path + newQuery + parts.postamble
        done null, replacement
        return

  pusher: (options) ->
    if not @enabled
      return new stream.PassThrough objectMode: true
    options = options or {}
    resolver = @resolver
    tagger = @getTagger options.base
    debug = @debug
    streamHasher
      tagger: tagger
      optioner: @pushOptioner.bind @, tagger, options
    .on 'digest', (digest, oldTag, newTag) ->
      debug 'pusher tag=%s', oldTag
      resolver.push oldTag, null, digest: digest, tag: newTag

  puller: (options) ->
    if not @enabled
      return new stream.PassThrough objectMode: true
    streamReplacer
      tagger: @getTagger()
      optioner: @pullOptioner.bind @, options


factory = (options) ->
  new Crusher options

factory.Crusher = Crusher

module.exports = factory
