'use strict'

fs = require 'fs'
path = require 'path'
_ = require 'lodash'

class ExtractorCatalog
  constructor: (options) ->
    @_classes = {}
    @_handles = {}
    options = options or {}
    scan = options.scan
    if scan != false
      if _.isString scan
        scanDir = scan
      else
        scanDir = path.join __dirname, './extractors'
      @scanExtractors scanDir, options

  scanExtractors: (scanDir, options) ->
    fileNames = fs.readdirSync scanDir
    for fileName in fileNames
      Extractor = require path.join scanDir, fileName
      @registerClass Extractor, options

  registerExts: (handle, exts) ->
    if exts
      if not _.isArray exts
        exts = [exts]
      for ext in exts
        @_handles[ext] = handle

  registerClass: (Extractor, options) ->
    options = options or {}
    @_classes[Extractor.handle] = Extractor
    if options.withExts != false
      @registerExts Extractor.handle, Extractor.exts

  getClass: (handle) ->
    @_classes[handle]

  getHandle: (ext) ->
    @_handles[ext]

  getExtractor: (file, options) ->
    ext = path.extname file.path
    handle = @getHandle ext
    Extractor = @getClass handle
    if Extractor?
      new Extractor options


factory = (options) ->
  new ExtractorCatalog options
factory.ExtractorCatalog = ExtractorCatalog

module.exports = factory





