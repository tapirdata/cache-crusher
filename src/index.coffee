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


class Replacer
  constructor: (@path) ->
    @pattern = new RegExp 'f[a-z]*'
    @minSearchLen = 256

  getReplace: (match, cb) ->
      cb match[0].toUpperCase()

  makeStream: () ->
    replacer = this
    hoard = ''

    forward = (minSearchLen, stream, cb) ->
      console.log 'forward hoard.length=%d hoard=%s...', hoard.length, hoard.substr 0, 12
      if hoard.length > minSearchLen
        match = replacer.pattern.exec hoard
        if match
          console.log 'match[0]=%s match.index=%d', match[0], match.index
          replacer.getReplace match, (replace) ->
            console.log 'replace=%s', replace
            stream.push hoard.substr 0, match.index
            stream.push replace
            hoard = hoard.substr match.index + match[0].length
            forward minSearchLen, stream, cb
            return
          return
        fwdIndex = hoard.length - minSearchLen
        stream.push hoard.substr 0, fwdIndex
        hoard = hoard.substr fwdIndex
      cb()
      return

    transformFunction = (chunk, enc, cb) ->
      console.log 'replacer', replacer.path, chunk.length
      hoard = hoard + String chunk, enc
      forward replacer.minSearchLen, this, cb

    flushFunction = (cb) ->
      console.log 'flush'
      forward 0, this, cb

    th = through2 transformFunction, flushFunction

    th.on 'end', ->
      console.log 'DONE'
    th


  replaceBuffer: (contents, cb) ->
    # TODO
    hoard = String contents + 'xxxx'
    cb(Buffer hoard)


class Receipt
  constructor: (@expirer) ->

class DefaultReceipt extends Receipt
  pattern: 'eels'
  replacer: ->
     'aale'


class Expirer
  constructor: (options) ->
    @tgtPath = options.tgtPath or '.'
    @_hashes = {}
    @_extReceipts = {}


  setHash: (file, hash) ->
    p = path.relative @tgtPath, file.path
    console.log 'setHash ', p, hash
    @_hashes[p] = hash


  makeHasher: (file) ->
    new Hasher this, file

  receiptClasses:
    default: DefaultReceipt

  getReceipt: (file) ->
    ext = path.extname file.relative
    receipt = @_extReceipts[ext]
    if not receipt
      Receipt = @receiptClasses[ext]
      if not Receipt
        Receipt = @receiptClasses['default']
      receipt = new Receipt this
      @_extReceipts[ext] = receipt
    receipt

  target: ->
    through2.obj (file, enc, cb) =>
      console.log 'file:', file.isStream(), file.path
      hasher = @makeHasher file
      if file.isStream()
        file.contents = file.contents.pipe hasher.makeStream()
      else  
        hasher.update file.contents
        hasher.complete()
      cb null, file
      return

  source: ->
    through2.obj (file, enc, cb) =>
      if file.isNull()
        cb(null, file);
        return
      # receipt = @getReceipt file
      replacer = new Replacer 'a/b'
      if file.isStream()
        file.contents = file.contents.pipe replacer.makeStream()
        cb null, file
        return
      replacer.replaceBuffer file.contents, (contents) ->
        file.contents = contents
        cb null, file
        return
      return


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
