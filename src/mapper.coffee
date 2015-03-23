'use strict'

path = require 'path'
_ = require 'lodash'
minimatch = require 'minimatch'

escapeRegExp = (s) ->
  s.replace /[-\/\\^$*+?.()|[\]{}]/g, '\\$&'


ensureEndSlash = (p) ->
  if p[p.length - 1] == '/'
    p
  else
    p + '/'


class Entry
  constructor: (options) ->
    @fsRoot = ensureEndSlash options.fsRoot
    @urlRoot = ensureEndSlash options.urlRoot
    @urlPattern = new RegExp "^#{escapeRegExp @urlRoot}(.*)"
    @fsPattern = new RegExp "^#{escapeRegExp @fsRoot}(.*)"
    @_setupMms options.globs

  _setupMms: (globs) ->
    mms = null
    if globs
      mms = []
      if not _.isArray globs
        globs = [globs]
      for glob in globs   
        mm = new minimatch.Minimatch glob
        mms.push mm
      if mms.length == 0
        mms = null
    @_mms = mms    
    return

  checkGlob: (rel) ->
    mms = @_mms
    if not mms?
      return true
    ok = null
    for mm in mms
      if ok == null or ok == mm.negate
        ok = mm.match rel
    ok    

  getUrlRel: (urlPath) ->
    match = @urlPattern.exec urlPath
    if not match?
      return
    rel = match[1]
    if @checkGlob rel
      rel

  getFsRel: (fsPath) ->
    match = @fsPattern.exec fsPath
    if not match?
      return
    rel = match[1]
    console.log 'getFsRel fsPath=%s rel=%s', fsPath, rel
    if @checkGlob rel
      rel


class Mapper 

  constructor: (options) ->
    options = options or {}
    entries = []
    for cp in options.counterparts or []
      entries.push new Entry cp
    @entries = entries

  checkUrlPath: (urlPath) ->
    for entry in @entries
      rel = entry.getUrlRel urlPath
      if rel?
        return true
    false  

  checkFsPath: (fsPath) ->
    console.log 'checkFsPath fsPath=%s', fsPath
    for entry in @entries
      rel = entry.getFsRel fsPath
      if rel?
        return true
    false  

  toFsPath: (urlPath) ->
    for entry in @entries
      rel = entry.getUrlRel urlPath
      if rel?
        return path.join entry.fsRoot, rel

  toUrlPath: (fsPath) ->
    for entry in @entries
      rel = entry.getFsRel fsPath
      if rel?
        return path.join entry.urlRoot, rel


factory = (options) ->
  new Mapper options

factory.Mapper = Mapper

module.exports = factory

  

