crypto = require 'crypto'
es = require 'event-stream'
_ = require 'lodash'
through2 = require 'through2'
replaceStream = require 'replacestream'

class Expirer
  constructor: (@options) ->
    @_hashes = {}

  hashOfFile: (file, cb) ->
    # console.log 'hashOfFile', file.relative
    hashStream = crypto.createHash 'sha1';
    
    back = -> 
      hash = hashStream.read().toString 'hex';
      # console.log 'hashOfFile->', hash 
      cb null, hash
      return

    file.clone().pipe hashStream
    if file.isBuffer()
      back()
    else
      hashStream.on 'unpipe', ->
        back()

  scan: ->
    es.map (file, cb) =>
      # console.log 'scan', file.relative
      hash = @hashOfFile file, (err, hash) =>
        if err
          cb err, file
        else  
          @_hashes[file.relative] = hash
          cb null, file
        return

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
