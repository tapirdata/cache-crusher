'use strict'


class Extractor

  preambleBrickNum: 2
  pathBrickNum: 1

  constructor: (options) ->
    options = options or {}
    @base = options.base or ''

  getBasenameBrick: ->
    '[\\w\\._-]+'

  getDirpartBrick: ->
    '[\\w\\._-]*'

  getPathBrick: ->
    "#{@base}(?:#{@getDirpartBrick()}/)*#{@getBasenameBrick()}"

  getPreBrick: ->
    ''

  getPostBrick: ->
    ''

  getOpenBrick: ->
    '[\'"]'

  getCloseBrick: ->
    '\\2'

  getBrick: ->
    parts = [
      '(', @getPreBrick(), ')'
      '(', @getOpenBrick(), ')'
      '(', @getPathBrick(), ')'
      '(', @getCloseBrick(), ')'
      '(', @getPostBrick(), ')'
    ]  
    parts.join ''

  createPattern: ->
    new RegExp @getBrick()

  getPattern: ->
    pattern = @_pattern
    if not pattern?
      pattern = @createPattern()
      @_pattern = pattern
    pattern

  split: (match) ->
    preambleCut = 1 + @preambleBrickNum
    pathCut = preambleCut + @pathBrickNum
    preamble: match.slice(1, preambleCut).join ''
    path: match.slice(preambleCut, pathCut).join ''
    postamble: match.slice(pathCut).join ''



class HtmlExtractor extends Extractor
  constructor: (options) ->
    super options

  getPreBrick: ->
    'src\\s*=\\s*'


factory = (options) ->
  new Extractor options

factory.Extractor = Extractor
factory.HtmlExtractor = HtmlExtractor

module.exports = factory



  

# extractor = new HtmlExtractor base: '/app/'
# s = '<img src  = "/app/cc/main.css" />'
# pattern = extractor.getPattern()
# match = pattern.exec s
# console.log 'match=', match
# console.log 'split->', extractor.split match
  

