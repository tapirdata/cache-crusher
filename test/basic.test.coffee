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

makeTests = (title, options) ->

  pushSrcDir = path.join fixtureDir, options.srcDir, 'push'
  pullSrcDir = path.join fixtureDir, options.srcDir, 'pull'
  pushExpDir = path.join fixtureDir, options.expDir, 'push'
  pullExpDir = path.join fixtureDir, options.expDir, 'pull'

  defaultCounterparts = [
    {
      urlRoot: '/app'
      tagRoot: path.relative(__dirname, pushSrcDir)
      # globs: ['**/*.css', '**/*.js']
      globs: ['*.css', '*.js']
      globOptions: matchBase: true
      # crushOptions: digestLength: null
    }
  ]

  defaultCrusherOptions =
    # debug: true
    # enabled: false
    cwd: __dirname
    extractor:
      urlBase: '/app/'
    mapper:
      counterparts: defaultCounterparts
    resolver:
      timeout: 1000
    crush:
      rename: 'postfix'
      # append: 'momo'

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

  pushOptions = options.push or {}
  pullOptions = options.pull or {}

  describe title, ->

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

        crusherOptions = defaultCrusherOptions
        if options.crusher
          crusherOptions = _.merge {}, crusherOptions, options.crusher
        crusher = cacheCrusher crusherOptions

        runPush = ->
          pushWell = vinylFs.src '**/*.*',
            cwd: pushSrcDir
            buffer: pushOptions.useBuffer
          pushWell
            .pipe crusher.pusher()
            .pipe pushTapper
            .on 'end', streamDone

        runPull = ->
          pullWell = vinylFs.src '**/*.*',
            cwd: pullSrcDir
            buffer: pullOptions.useBuffer
          pullWell
            .pipe crusher.puller()
            .pipe pullTapper
            .on 'end', streamDone

        setTimeout runPush, pushOptions.delay
        setTimeout runPull, pullOptions.delay


    it 'should write the expected push files', ->
      compareResultsExps pushResults, pushExps

    it 'should write the expected pull files', ->
      compareResultsExps pullResults, pullExps


describe 'cache-crusher', ->

  makeTests 'Simple postfix',
    srcDir: 'simple-src'
    expDir: 'simple-exp-postfix'

  makeTests 'Simple postfix with pull buffer',
    srcDir: 'simple-src'
    expDir: 'simple-exp-postfix'
    pull:
      useBuffer: true

  makeTests 'Simple postfix with push buffer',
    srcDir: 'simple-src'
    expDir: 'simple-exp-postfix'
    push:
      useBuffer: true

  makeTests 'Simple postfix with push delay',
    srcDir: 'simple-src'
    expDir: 'simple-exp-postfix'
    push:
      delay: 500

  makeTests 'Simple postfix with pull delay',
    srcDir: 'simple-src'
    expDir: 'simple-exp-postfix'
    pull:
      delay: 500

  makeTests 'Simple append',
    srcDir: 'simple-src'
    expDir: 'simple-exp-append'
    crusher:
      crush:
        rename: false
        append: 'rev'



