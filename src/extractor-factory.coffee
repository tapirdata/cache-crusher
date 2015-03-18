'use strict'

fs = require 'fs'
path = require 'path'
_ = require 'lodash'

class ExtractorFactory
  constructor: (options) ->
    @classByLabel = {}
    @labelByType = {}
    options = options or {}
    scan = options.scan 
    if scan != false
      if _.isString scan
        scanDir = scan
      else
        scanDir = path.join __dirname, './extractors'
      @scanExtractors scanDir, options.withTypes

  scanExtractors: (scanDir, withTypes) ->
    fileNames = fs.readdirSync scanDir
    for fileName in fileNames
      E = require path.join scanDir, fileName
      console.log 'fileName=%s label=%s', fileName, E.label
      @registerClass E, withTypes

  registerTypes: (label, types) ->  
    if types
      for type in types
        @labelByType[type] = label

  registerClass: (E, withTypes) ->  
    @classByLabel[E.label] = E
    if withTypes != false
      @registerTypes E.label, E.types
  
  classOfLabel: (label) ->
    @classByLabel[label]

  classOfType: (type) ->
    label = @labelByType[type]
    @classByLabel[label]

factory = (options) ->
  new ExtractorFactory options
factory.ExtractorFactory = ExtractorFactory

module.exports = factory


    


