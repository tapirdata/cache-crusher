'use strict'


class Extractor
  constructor: (options) ->
    options = options or {}
    @base = options.base or ''

  createDirBrick: ->
    part = '[\\w\\._-]*'
    "#{@base}(?:#{part}/)*"

  createBasenameBrick: ->
    '[\\w\\._-]+'

  createPreBrick: ->
    ''

  createPostBrick: ->
    ''

  createOpenBrick: ->
    '[\'"]'

  createCloseBrick: ->
    '\\2'


  createRegExp: ->
    parts = [
      '(', @createPreBrick(), ')'
      '(', @createOpenBrick(), ')'
      '(', @createDirBrick(), ')'
      '(', @createBasenameBrick(), ')'
      '(', @createCloseBrick(), ')'
      '(', @createPostBrick(), ')'
    ]  
    new RegExp parts.join('')


class HtmlExtractor extends Extractor
  constructor: (options) ->
    super options



module.exports = 
  Extractor: Extractor
  HtmlExtractor: HtmlExtractor

e = new HtmlExtractor base: '/app/'
s = '<img src="/app/cc/main.css" />'
r = e.createRegExp()
m = r.exec s
console.log 'match=', m
console.log 'ori=', m.slice(1).join ''
  

