'use strict'

class Extractor

  @label: 'base'

  preambleBrickNum: 2
  pathBrickNum: 1

  partBrick: '[\\w\\._-]+'
  preBrick: ''
  postBrick: ''
  openBrick: '[\'"]'
  closeBrick: '\\2'

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
    preamble: match.slice(1, preambleCut).join ''
    path: match.slice(preambleCut, pathCut).join ''
    postamble: match.slice(pathCut).join ''

module.exports = Extractor


