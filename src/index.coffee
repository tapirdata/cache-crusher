crypto = require 'crypto'
es = require 'event-stream'
_ = require 'lodash'
gutil = require 'gulp-util'

class Expirer
  constructor: (@options) ->
    @_hashes = {}

  getHash: (file, cb) ->
    # console.log 'getHash', file.relative
    hashStream = crypto.createHash 'sha1';
    
    back = -> 
      hash = hashStream.read().toString 'hex';
      # console.log 'getHash->', hash 
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
      hash = @getHash file, (err, hash) =>
        if err
          cb err, file
        else  
          @_hashes[file.relative] = hash
          cb null, file
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
