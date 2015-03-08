fs = require 'fs'
path = require 'path'
es = require 'event-stream'
_ = require 'lodash'
_eval = require 'eval'
vinylFs = require 'vinyl-fs'
chai = require 'chai'
expect = chai.expect
expirer = require '../src/index'

targetPath1 = 'fixtures/eels.txt'

targetHashes = {}
targetHashes[targetPath1] = '15390ef2ebb49260800bde88fda1e054791bb5fb'

sourceCheckers =
  'fixtures/main.js': (data) ->
     console.log 'main.js: data="%s..."', data.substr 0, 36
      ## foo = _eval data
      ## expect(foo()).to.be.equal 'app/x/aale.text'


withStreamData = (stream, cb) ->
  stream.on 'data', (file) ->
    expect(file).to.exist
    expect(file.contents).to.exist

    if file.isBuffer()
      data = file.contents
      cb(file, String data)
    else
      file.contents.pipe es.wait (err, data) ->
        cb(file, String data)
        return
    return
  stream.on 'end', ->
    # console.log 'END'
    cb()
  return


checkTarget = (stream, done) ->
  withStreamData stream, (file, data) ->
    if file
      reqData = fs.readFileSync file.path, 'utf8'
      expect(data).to.be.equal reqData
    else
      done()
    return
  return


checkSource = (stream, done) ->
  withStreamData stream, (file, data) ->
    if file
      p = path.relative __dirname, file.path
      console.log 'checkSource p=', p
      checker = sourceCheckers[p]
      if checker
        checker data
    else
      done()
    return
  

makeTests = (title, options) ->

  describe title, ->
    targetStream = null
    exp1 = null
    before ->
      exp1 = expirer tgtPath: __dirname 
      targetStream = vinylFs.src 'fixtures/**/*',
        cwd: __dirname
        buffer: not options.targetStream
      targetStream = targetStream.pipe exp1.target()

    it 'should pass target unmodified', (done) ->
      checkTarget targetStream, done

    it 'should have correct hashes of targets', ->
      for p, hash of targetHashes
        expect(exp1._hashes[p]).to.be.equal hash
   
    it 'should replace in source ' + (if options.sourceStream then '(stream)' else '(buffer)'), (done) ->
      sourceStream = vinylFs.src 'fixtures/**/*.js',
        cwd: __dirname
        buffer: not options.sourceStream
      sourceStream = sourceStream.pipe exp1.source()
      checkSource sourceStream, done


describe 'gulp-expirer', ->

  makeTests 'Buffer target',
    targetStream: false
    sourceStream: true

  makeTests 'Stream target',
    targetStream: true
    sourceStream: false

