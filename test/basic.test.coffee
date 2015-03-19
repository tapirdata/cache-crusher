fs = require 'fs'
path = require 'path'
_ = require 'lodash'
vinylFs = require 'vinyl-fs'
vinylTapper = require 'vinyl-tapper'
chai = require 'chai'
expect = chai.expect
assert = chai.assert
cacheCrusher = require '../src/index'


readTree = (srcRoot, srcBase, done) ->
  # console.log 'readTree srcRoot=%s, srcBase=%s', srcRoot, srcBase
  walk = require 'walk' 
  walker = walk.walk srcRoot
  results = {}

  walker.on 'file', (src, stat, next) ->
    srcPath = path.join src, stat.name
    # console.log 'readTree src=%s, name=%s', src, stat.name
    fs.readFile srcPath, (err, srcBuffer) ->
      if err
        next err
        return
      results[path.relative srcBase, srcPath] = srcBuffer
      next()
      return

  walker.on 'end', ->
    done null, results


compareResultsExps = (results, exps) ->
  misses = []
  extras = []
  for p of exps
    if not results[p]?
      misses.push p
  for p of results
    if not exps[p]
      extras.push p
  assert misses.length == 0 and extras.length == 0, ->
    parts = []
    if misses.length
      parts.push (_.map misses, (s) -> "'#{s}'").join(', ') + ' missing'
    if extras.length
      parts.push (_.map extras, (s) -> "'#{s}'").join(', ') + ' superfluous'
    'Paths differ: ' + parts.join '; '

  for p, result of results
    expBuffer = exps[p]
    expect(result.buffer.toString 'utf8').to.be.equal expBuffer.toString 'utf8'


fixtureDir = path.join __dirname, 'fixtures'

makeTests = (title, set, options) ->

  pushSrcDir = path.join fixtureDir, set.srcDir, 'push'
  pullSrcDir = path.join fixtureDir, set.srcDir, 'pull'
  pushExpDir = path.join fixtureDir, set.expDir, 'push'
  pullExpDir = path.join fixtureDir, set.expDir, 'pull'

  pushResults = {}
  pullResults = {}

  pushTapper = vinylTapper
    provideBuffer: true
    terminate: true
  pushTapper.on 'tap', (file, buffer) ->  
    pushResults[file.relative] = 
      file: file
      buffer: buffer

  pullTapper = vinylTapper
    provideBuffer: true
    terminate: true
  pullTapper.on 'tap', (file, buffer) ->  
    pullResults[file.relative] = 
      file: file
      buffer: buffer

  pushExps = null
  pullExps = null
  readExps = (cb) ->
    readTree pushExpDir, pushExpDir, (err, results) ->
      pushExps = results
      if err
        cb err
        return
      readTree pullExpDir, pullExpDir, (err, results) ->
        pullExps = results
        if err
          cb err
          return
        cb()

  modeName = (useBuffer) ->
    if useBuffer
      'buffer'
    else
      'stream'


  counterparts = [
    (urlRoot: '/app/', fsRoot: path.relative __dirname, pushSrcDir)
  ]

  describe "#{title} with push #{modeName options.usePushBuffer}, with pull #{modeName options.usePullBuffer}", ->

    crusher = null

    before (done) ->
      readExps (err) ->
        if err
          done err
          return

        streamCount = 2
        streamDone = ->
          if --streamCount == 0
            done()
          return  

        crusher = cacheCrusher
          cwd: __dirname
          extractor:
            urlBase: '/app/'
          mapper:
            counterparts: counterparts
          resolver:
            timeout: 1000

        pushWell = vinylFs.src '**/*.*',
          cwd: pushSrcDir 
          buffer: options.usePushBuffer
        pushWell
          .pipe crusher.pusher()
          .pipe pushTapper
          .on 'end', streamDone

        pullWell = vinylFs.src '**/*.*',
          cwd: pullSrcDir 
          buffer: options.usePullBuffer
        pullWell
          .pipe crusher.puller()
          .pipe pullTapper
          .on 'end', streamDone
    
    it 'should write the expected push files', ->
      compareResultsExps pushResults, pushExps

    it 'should write the expected pull files', ->
      compareResultsExps pullResults, pullExps


describe 'cache-crusher', ->

  simpleSet =
    srcDir: 'simple-src'
    expDir: 'simple-exp'

  makeTests 'Simple',
    simpleSet
    usePushBuffer: false
    usePullBuffer: true

  makeTests 'Simple',
    simpleSet
    usePushBuffer: true
    usePullBuffer: false


