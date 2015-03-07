fs = require 'fs'
es = require 'event-stream'
_ = require 'lodash'
_eval = require 'eval'
VinylFile = require 'vinyl'
chai = require 'chai'
expect = chai.expect
expirer = require '../src/index'

scanPath1 = 'test/fixtures/eels.txt'
scanData1 = fs.readFileSync scanPath1, 'utf8'
scanHash1 = '15390ef2ebb49260800bde88fda1e054791bb5fb'

replacePath1 = 'test/fixtures/main.js'

withStreamData = (stream, cb) ->
  stream.on 'data', (result) ->
    expect(result).to.exist
    expect(result.contents).to.exist

    if result.isBuffer()
      data = result.contents
      cb(String data)
    else
      result.contents.pipe es.wait (err, data) ->
        cb(String data)
        return
    return
  return


checkStreamData = (stream, reqData, done) ->
  withStreamData stream, (data) ->
    expect(data).to.be.equal reqData
    done()
    return
  return


checkReplace = (exp, replaceFile, done) ->
  replaceStream = exp.replace()

  withStreamData replaceStream, (data) ->
    # console.log 'replace data=', data
    foo = _eval data
    expect(foo()).to.be.equal 'app/x/eels.text'
    done()
    return
  
  replaceStream.write replaceFile
  replaceStream.end()


makeTests = (title, options) ->

  describe title, ->
    scanFile1 = null
    exp1 = null
    before ->
      if options.scanStream
        scanFile1 = new VinylFile
          contents: fs.createReadStream scanPath1
          path: scanPath1
      else
        scanFile1 = new VinylFile
          contents: fs.readFileSync scanPath1
          path: scanPath1
      exp1 = expirer tt: 3

    it 'should pass unmodified', (done) ->
      scanStream = exp1.scan()
      checkStreamData scanStream, scanData1, done

      scanStream.write scanFile1
      scanStream.end()

    it 'should have correct hash', ->
      expect(exp1._hashes[scanPath1]).to.be.equal scanHash1
   
    it 'should replace in buffer-file', (done) ->
      replaceFile1 = new VinylFile
        contents: fs.readFileSync replacePath1
        path: replacePath1
      checkReplace exp1, replaceFile1, done  

    it 'should replace in stream-file', (done) ->
      replaceFile1 = new VinylFile
        contents: fs.createReadStream replacePath1
        path: replacePath1
      checkReplace exp1, replaceFile1, done  



describe 'gulp-expirer', ->

  makeTests 'Buffer input',
    scanStream: false

  makeTests 'Stream input',
    scanStream: true

