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

  checkRel: (rel) ->
    @checkGlob rel

  getUrlRel: (url) ->
    match = @urlPattern.exec url
    if match?
      match[1]

  getTagRel: (tag) ->
    match = @tagPattern.exec tag
    if match?
      match[1]

  getTag: (rel) ->
    path.join @tagRoot, rel

  getUrl: (rel) ->
    path.join @urlRoot, rel

  toString: () ->
    util.format "Entry({urlRoot='%s', tagRoot='%s', globs=%s, crushOptions=%j})", @urlRoot, @tagRoot, @globs, @crushOptions


class Hit
  constructor: (@entry, @rel) ->

  getCrushOptions: (options) ->
    if @entry.crushOptions
      options = _.merge {}, options, @entry.crushOptions
    options  

  getTag: (url) ->
    rel = if url? then @entry.getUrlRel url else @rel
    @entry.getTag rel

  getUrl: (tag) ->  
    rel = if tag? then @entry.getTagRel tag else @rel
    @entry.getUrl rel

  toString: () ->
    util.format "Hit({entry=%s, rel=%s})", @entry, @rel


class Mapper

  constructor: (options) ->
    options = options or {}
    entries = []
    for cp in options.counterparts or []
      entries.push new Entry cp
    @entries = entries

  getUrlHit: (url) ->
    for entry in @entries
      rel = entry.getUrlRel url
      if rel? and entry.checkRel rel
        return new Hit entry, rel

  getTagHit: (tag) ->
    for entry in @entries
      rel = entry.getTagRel tag
      if rel? and entry.checkRel rel
        return new Hit entry, rel


factory = (options) ->
  new Mapper options

factory.Mapper = Mapper

module.exports = factory



