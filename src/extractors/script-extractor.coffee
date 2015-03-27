'use strict'

Extractor = require './extractor'


class ScriptExtractor extends Extractor
  @handle: 'script'
  @exts: ['.js', '.coffee']

  constructor: (options) ->
    super options

  openBrick: '\\\\?[\'"]' # if the url appears inside a string, its quotes will be escaped


module.exports = ScriptExtractor


