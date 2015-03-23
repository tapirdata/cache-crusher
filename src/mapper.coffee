'use strict'

path = require 'path'

escapeRegExp = (s) ->
  s.replace /[-\/\\^$*+?.()|[\]{}]/g, '\\$&'

class Entry
  constructor: (options) ->
    @fsRoot = options.fsRoot
    @urlRoot = options.urlRoot
    @glob = options.glob
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

  constructor: (options) ->
    options = options or {}
    entries = []
    for cp in options.counterparts or []
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


factory = (options) ->
  new Mapper options

factory.Mapper = Mapper

module.exports = factory

  

