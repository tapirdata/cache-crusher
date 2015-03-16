path = require 'path'
crypto = require 'crypto'
_ = require 'lodash'
streamHasher = require 'stream-hasher'
streamReplacer = require 'stream-replacer'


class Crusher
  constructor: (@options) ->


factory = (options) ->
  new Crusher options

factory.Crusher = Crusher

module.exports = factory
