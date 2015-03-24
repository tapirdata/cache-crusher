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
    @crushOptions = options.crushOptions
    @tagRoot = ensureEndSlash options.tagRoot
    @urlRoot = ensureEndSlash options.urlRoot
    @urlPattern = new RegExp "^#{escapeRegExp @urlRoot}(.*)"
    @tagPattern = new RegExp "^#{escapeRegExp @tagRoot}(.*)"
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

  getUrlRel: (url) ->
    match = @urlPattern.exec url
    if not match?
      return
    rel = match[1]
    if @checkGlob rel
      rel

  getTagRel: (tag) ->
    match = @tagPattern.exec tag
    if not match?
      return
    rel = match[1]
    if @checkGlob rel
      rel

  getTag: (rel) ->
    path.join @tagRoot, rel

  getUrl: (rel) ->
    path.join @urlRoot, rel


class Mapper

  constructor: (options) ->
    options = options or {}
    entries = []
    for cp in options.counterparts or []
      entries.push new Entry cp
    @entries = entries

    debug = options.debug
    if debug
      if typeof debug != 'function'
        debug = console.err
      @debug = debug

  debug: ->

  getUrlMap: (url) ->
    for entry in @entries
      rel = entry.getUrlRel url
      if rel?
        return {
          entry: entry
          rel: rel
        }
    return {}

  getTagMap: (tag) ->
    for entry in @entries
      rel = entry.getTagRel tag
      if rel?
        return {
          entry: entry
          rel: rel
        }
    return {}


factory = (options) ->
  new Mapper options

factory.Mapper = Mapper

module.exports = factory



