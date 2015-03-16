'use strict'

path = require 'path'
_ = require 'lodash'
streamHasher = require 'stream-hasher'
streamReplacer = require 'stream-replacer'


class Crusher
  constructor: (@options) ->

  pusher: ->
    streamHasher
      digestLength: 8
      rename: 'postfix'

  puller: ->
    streamReplacer
      pattern: /eels/
      substitute: ->
        'limuli'


factory = (options) ->
  new Crusher options

factory.Crusher = Crusher

module.exports = factory
