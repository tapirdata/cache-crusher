'use strict'

Extractor = require './extractor'


class HtmlExtractor extends Extractor
  @handle: 'html'
  @exts: ['.html', '.xml', '.jade']

  constructor: (options) ->
    super options

  preBrick: '(?:src|href)\\s*=\\s*'

# factory = (options) ->
#   new HtmlExtractor options
# 
# factory.Extractor = Extractor
# factory.HtmlExtractor = HtmlExtractor

module.exports = HtmlExtractor


