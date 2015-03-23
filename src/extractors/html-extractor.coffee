'use strict'

Extractor = require './extractor'


class HtmlExtractor extends Extractor
  @handle: 'html'
  @exts: ['.html', '.xml', '.jade']

  constructor: (options) ->
    super options

  preBrick: '(?:src|href)\\s*=\\s*'


module.exports = HtmlExtractor


