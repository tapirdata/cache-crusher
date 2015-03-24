'use strict'

class Extractor

  @handle: 'base'

  preambleBrickNum: 2
  pathBrickNum: 1
  queryBrickNum: 1

  partBrick: '[^\/#?\'"]+'
  preBrick: ''
  postBrick: ''
  openBrick: '[\'"]'
  closeBrick: '\\2'
  queryBrick: '(?:\\?[^#"\']*)?'

  constructor: (options) ->
    options = options or {}
    @base = options.base or ''
    if options.partBrick
      @partBrick = options.partBrick
    @pathBrick = "#{@base}(?:#{@partBrick}/)*#{@partBrick}"

  getBrick: ->
    brickParts = [
      '(', @preBrick, ')'
      '(', @openBrick, ')'
      '(', @pathBrick, ')'
      '(', @queryBrick, ')'
      '(', @closeBrick, ')'
      '(', @postBrick, ')'
    ]
    brickParts.join ''

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
    queryCut = pathCut + @queryBrickNum
    preamble: match.slice(1, preambleCut).join ''
    path: match.slice(preambleCut, pathCut).join ''
    query: match.slice(pathCut, queryCut).join ''
    postamble: match.slice(queryCut).join ''

module.exports = Extractor


