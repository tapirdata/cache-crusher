'use strict'

util = require 'util'
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
    @globs = options.globs
    @globOptions = options.globOptions
    @crushOptions = options.crushOptions
    @tagRoot = ensureEndSlash options.tagRoot
    @urlRoot = ensureEndSlash options.urlRoot
    @urlPattern = new RegExp "^#{escapeRegExp @urlRoot}(.*)"
    @tagPattern = new RegExp "^#{escapeRegExp @tagRoot}(.*)"
    @_setupMms()

  _setupMms: ->
    globs = @globs
    mms = null
    if globs
      mms = []
      if not _.isArray globs
        globs = [globs]
      for glob in globs
        mm = new minimatch.Minimatch glob, @globOptions
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

  toString: () ->
    util.format "Entry({urlRoot='%s', tagRoot='%s', globs=%s, crushOptions=%j})", @urlRoot, @tagRoot, @globs, @crushOptions


class Map
  constructor: (@entry, @rel) ->

  toString: () ->
    util.format "Map({entry=%s, rel=%s})", @entry, @rel


class Mapper

  constructor: (options) ->
    options = options or {}
    entries = []
    for cp in options.counterparts or []
      entries.push new Entry cp
    @entries = entries

  getUrlMap: (url) ->
    for entry in @entries
      rel = entry.getUrlRel url
      if rel?
        return new Map entry, rel
    return {}

  getTagMap: (tag) ->
    for entry in @entries
      rel = entry.getTagRel tag
      if rel?
        return new Map entry, rel
    return {}


factory = (options) ->
  new Mapper options

factory.Mapper = Mapper

module.exports = factory



