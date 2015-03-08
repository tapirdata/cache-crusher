path = require 'path'
crypto = require 'crypto'
es = require 'event-stream'
_ = require 'lodash'
through2 = require 'through2'


class Hasher
  constructor: (@expirer, @file) ->
    @hashStream = crypto.createHash 'sha1'

  update: (chunk) ->
    @hashStream.update chunk
    return

  complete: ->
    hash = @hashStream.digest 'hex'
    @expirer.setHash @file, hash


  makeStream: () ->
    hasher = this
    stream = through2 (chunk, enc, cb) ->
      console.log 'hasher', hasher.file.path, chunk.length
      hasher.hashStream.update chunk
      this.push chunk
      cb()
    stream.on 'end', ->
      hasher.complete()
    stream  


class Expirer
  constructor: (options) ->
    @tgtPath = options.tgtPath or '.'
    @_hashes = {}


  setHash: (file, hash) ->
    p = path.relative @tgtPath, file.path
    console.log 'setHash ', p, hash
    @_hashes[p] = hash


  makeHasher: (file) ->
    new Hasher this, file

  scan: ->
    through2.obj (file, enc, cb) =>
      console.log 'file:', file.isStream(), file.path
      hasher = @makeHasher file
      if file.isStream()
        file.contents = file.contents.pipe hasher.makeStream()
      else  
        hasher.update file.contents
        hasher.complete()
      cb null, file


  replace: ->
    receipt = @getReceipt()
    through2.obj (file, enc, cb) ->
      if file.isNull()
        cb(null, file);
      else if file.isBuffer()
        file.contents = new Buffer(
          String(file.contents).replace receipt.pattern, receipt.replacer
        )  
        cb(null, file);
      else  
        file.contents = file.contents.pipe replaceStream receipt.pattern, receipt.replacer
        cb(null, file);

  makeReceipt: ->
    receipt =
      pattern: 'eels'
      replacer: ->
        'aale'
    receipt   

  getReceipt: ->
    if not @_receipt
      @_receipt = @makeReceipt()
    @_receipt  


namedExpirers = {}

expirer = (options) ->
  if _.isString(options)
    options = name: options
  options = options or {}
  name = options.name or 'default'
  expirer = namedExpirers[name]
  if not expirer
    expirer = namedExpirers[name] = new Expirer options
  expirer

expirer.Expirer = Expirer

module.exports = expirer
