'use strict'

path = require 'path'

escapeRegExp = (s) ->
  s.replace /[-\/\\^$*+?.()|[\]{}]/g, '\\$&'

class Entry
  constructor: (options) ->
    @fsRoot = options.fsRoot
    @urlRoot = options.urlRoot
    @urlPattern = new RegExp "^#{escapeRegExp options.urlRoot}(.*)"
    @fsPattern = new RegExp "^#{escapeRegExp options.fsRoot}(.*)"

  toFsPath: (urlPath) ->
    match = @urlPattern.exec urlPath
    if not match?
      return
    path.join @fsRoot, match[1]

  toUrlPath: (fsPath) ->
    match = @fsPattern.exec fsPath
    if not match?
      return
    path.join @urlRoot, match[1]


class Mapper 

  constructor: (counterparts, options) ->
    entries = []
    for cp in counterparts
      entries.push new Entry cp
    @entries = entries

  toFsPath: (urlPath) ->  
    for entry in @entries
      fsPath = entry.toFsPath urlPath
      if fsPath?
        return fsPath

  toUrlPath: (fsPath) ->  
    for entry in @entries
      urlPath = entry.toUrlPath fsPath
      if urlPath?
        return urlPath


factory = (counterparts, options) ->
  new Mapper counterparts, options

factory.Mapper = Mapper

module.exports = factory

  

