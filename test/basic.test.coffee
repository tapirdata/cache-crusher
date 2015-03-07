fs = require 'fs'
es = require 'event-stream'
_ = require 'lodash'
VinylFile = require 'vinyl'
chai = require 'chai'
expect = chai.expect
expirer = require '../src/index'

scanPath1 = 'test/fixtures/eels.txt'
scanData1 = fs.readFileSync scanPath1, 'utf8'
scanHash1 = '15390ef2ebb49260800bde88fda1e054791bb5fb'

repacePath1 = 'test/fixtures/main.js'

checkStreamData = (stream, cb) ->
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


checkStreamDataEqual = (stream, reqData, done) ->
  checkStreamData stream, (data) ->
    expect(data).to.be.equal reqData
    done()
    return
  return


describe 'gulp-expirer', ->

  describe 'Buffer input', ->
    file1 = null
    exp1 = null
    before ->
      file1 = new VinylFile
        contents: fs.readFileSync scanPath1
        path: scanPath1
      exp1 = expirer tt: 3

    it 'should pass unmodified', (done) ->
      stream = exp1.scan()
      checkStreamDataEqual stream, scanData1, done

      stream.write file1
      stream.end()

    it 'should have correct hash', ->
      expect(exp1._hashes[scanPath1]).to.be.equal scanHash1


  describe 'Stream input', ->
    file1 = null
    exp1 = null
    before ->
      file1 = new VinylFile
        contents: fs.createReadStream scanPath1
        path: scanPath1
      exp1 = expirer tt: 3

    it 'should pass unmodified', (done) ->
      stream = exp1.scan()
      checkStreamDataEqual stream, scanData1, done

      stream.write file1
      stream.end()

    it 'should have correct hash', ->
      expect(exp1._hashes[scanPath1]).to.be.equal scanHash1


