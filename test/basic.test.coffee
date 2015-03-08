fs = require 'fs'
path = require 'path'
es = require 'event-stream'
_ = require 'lodash'
_eval = require 'eval'
vinylFs = require 'vinyl-fs'
chai = require 'chai'
expect = chai.expect
expirer = require '../src/index'

scanPath1 = 'fixtures/eels.txt'

scanHashes = {}
scanHashes[scanPath1] = '15390ef2ebb49260800bde88fda1e054791bb5fb'

replacePath1 = 'fixtures/main.js'

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


checkStreamData = (stream, done) ->
  withStreamData stream, (file, data) ->
    if file
      reqData = fs.readFileSync file.path, 'utf8'
      expect(data).to.be.equal reqData
    else
      done()
    return
  return


checkReplace = (exp, replaceFile, done) ->
  replaceStream = exp.replace()

  withStreamData replaceStream, (data) ->
    # console.log 'replace data=', data
    foo = _eval data
    expect(foo()).to.be.equal 'app/x/aale.text'
    done()
    return
  
  replaceStream.write replaceFile
  replaceStream.end()


makeTests = (title, options) ->

  describe title, ->
    scanStream = null
    exp1 = null
    before ->
      exp1 = expirer tgtPath: __dirname 
      scanStream = vinylFs.src 'fixtures/**/*', cwd: __dirname, buffer: not options.scanStream
      scanStream = scanStream.pipe exp1.scan()

    it 'should pass unmodified', (done) ->
      checkStreamData scanStream, done

    it 'should have correct hashes', ->
      for p, hash of scanHashes
        expect(exp1._hashes[p]).to.be.equal hash
   
    # it 'should replace in buffer-file', (done) ->
    #   replaceFile1 = new VinylFile
    #     contents: fs.readFileSync replacePath1
    #     path: replacePath1
    #   checkReplace exp1, replaceFile1, done  

    # it 'should replace in stream-file', (done) ->
    #   replaceFile1 = new VinylFile
    #     contents: fs.createReadStream replacePath1
    #     path: replacePath1
    #   checkReplace exp1, replaceFile1, done  



describe 'gulp-expirer', ->

  makeTests 'Buffer input',
    scanStream: false

  makeTests 'Stream input',
    scanStream: true

