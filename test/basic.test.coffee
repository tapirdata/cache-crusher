fs = require 'fs'
path = require 'path'
_ = require 'lodash'
vinylFs = require 'vinyl-fs'
vinylTapper = require 'vinyl-tapper'
chai = require 'chai'
expect = chai.expect
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


  describe "#{title} with push #{modeName options.usePushBuffer}, with pull #{modeName options.usePullBuffer}", ->

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

        crusher = cacheCrusher()

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

    it 'should write the expected number of push files', ->
      # console.log 'pushExps=', pushExps
      # console.log 'pushResults=', pushResults
      expect(_.keys(pushResults).length).to.be.equal _.keys(pushExps).length

    it 'should write the expected number of pull files', ->
      # console.log 'pullExps=', pullExps
      # console.log 'pullResults=', pullResults
      expect(_.keys(pullResults).length).to.be.equal _.keys(pullExps).length
     
    it 'should write push files with expected paths', ->
      for p of pushExps
        expect(pushResults[p]).to.be.a 'object'

    it 'should write pull files with expected paths', ->
      for p of pullExps
        expect(pullResults[p]).to.be.a 'object'

    it 'should write push files with expected contents', ->
      for p, expBuffer of pushExps
        result = pushResults[p]
        expect(result.buffer.toString 'utf8').to.be.equal expBuffer.toString 'utf8'

    it 'should write pull files with expected contents', ->
      for p, expBuffer of pullExps
        result = pullResults[p]
        expect(result.buffer.toString 'utf8').to.be.equal expBuffer.toString 'utf8'




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


