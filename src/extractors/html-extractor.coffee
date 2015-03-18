'use strict'

Extractor = require './extractor'


class HtmlExtractor extends Extractor
  @label: 'html'
  @types: ['html', 'xml']

  constructor: (options) ->
    super options

  preBrick: '(?:src|href)\\s*=\\s*'

# factory = (options) ->
#   new HtmlExtractor options
# 
# factory.Extractor = Extractor
# factory.HtmlExtractor = HtmlExtractor

module.exports = HtmlExtractor


