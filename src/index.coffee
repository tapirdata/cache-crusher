'use strict'

path = require 'path'
_ = require 'lodash'
stream = require 'readable-stream'
streamHasher = require 'stream-hasher'
streamReplacer = require 'stream-replacer'


class Crusher

  @defaultResolverOptions:
    timeout: 10000

  @defaultMapperOptions: {}

  @defaultExtractorOptions:
    urlBase: '/static/'

  @defaultHasherOptions:
    rename: 'postfix'
    digestLength: 8

  constructor: (options) ->
    options = options or {}

    @setDebug options.debug
    @setEnabled options.enabled
    @cwd = options.cwd or process.cwd()
    if typeof options.getTagger == 'function'
      @getTagger = options.getTagger
    if typeof options.getExtractor == 'function'
      @getExtractor = options.getExtractor

    resolverOptions = _.merge {}, @constructor.defaultResolverOptions, options.resolver
    @resolver = resolverOptions._ or require('./resolver') resolverOptions

    mapperOptions = _.merge {}, @constructor.defaultMapperOptions, options.mapper
    @mapper = mapperOptions._ or require('./mapper') mapperOptions

    @hasherOptions = _.merge {}, @constructor.defaultHasherOptions, options.hasher

    extractorOptions = _.merge {}, @constructor.defaultExtractorOptions, options.extractor
    if not extractorOptions.catalog
      extractorOptions.catalog = require('./extractor-catalog')()
    @extractorOptions = extractorOptions

  setEnabled: (enabled) ->
    @enabled = enabled != false

  setDebug: (debug) ->
    if !debug
      debug = ->
    else if typeof debug != 'function'
      debug = console.error
    @debug = debug

  getTagger: (options) ->
    options = options or {}
    if options.relativeBase?
      (file) -> path.join options.relativeBase, file.relative
    else
      cwd = @cwd
      (file) -> path.relative cwd, file.path

  getExtractor: (file) ->
    catalog = @extractorOptions.catalog
    catalog.getExtractor file, @extractorOptions

  pushOptioner: (tagger, options, file) ->
    tag = tagger file
    hit = @mapper.getTagHit tag
    @debug "crusher.pushOptioner: tag='%s' hit=%s", tag, hit
    if not hit?
      return {}
    hit.getHasherOptions @hasherOptions

  pullOptioner: (options, file) ->
    self = @
    extractor = @getExtractor file
    if not extractor
      console.warn "no extractor for file '#{file.path}'"
      return pattern: null
    pattern: extractor.getPattern()
    substitute: (match, originTag, done) ->
      self.debug "crusher.puller: originTag='%s' match='%s'", originTag, match[0]
      parts = extractor.split match
      hit = self.mapper.getUrlHit parts.path
      self.debug "crusher.puller (substitute): url='%s' hit=%s", parts.path, hit
      if not hit?
        done()
        return
      self.resolver.pull hit.getTag(), originTag, (err, result) ->
        if err
          done err
          return
        if result.tag?
          newUrl = hit.getUrl result.tag
          replacement = parts.preamble + newUrl + parts.query + parts.postamble
          self.debug "crusher.puller (substitute): newUrl='%s'", newUrl
        else
          hasherOptions = hit.getHasherOptions self.hasherOptions
          if hasherOptions?
            append = hasherOptions.append
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
        self.debug "crusher.puller (substitute): replacement='%s'", replacement
        done null, replacement
        return

  pusher: (options) ->
    if not @enabled
      return new stream.PassThrough objectMode: true
    options = options or {}
    resolver = @resolver
    tagger = @getTagger options.tagger
    debug = @debug
    streamHasher
      tagger: tagger
      optioner: @pushOptioner.bind @, tagger, options
    .on 'digest', (digest, oldTag, newTag) ->
      debug "cusher.pusher: tag='%s'", oldTag
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
