fs = require 'fs'
gutil = require 'gulp-util'
through2 = require 'through2'
es = require 'event-stream'
_ = require 'lodash'
chai = require 'chai'
expect = chai.expect
expirer = require '../src/index'

path1 = 'test/fixtures/eels.txt'
data1 = fs.readFileSync path1, 'utf8'
hash1 = '15390ef2ebb49260800bde88fda1e054791bb5fb'

checkStreamData = (stream, reqData, done) ->
  stream.on 'data', (result) ->
    expect(result).to.exist
    expect(result.contents).to.exist

    if result.isBuffer()
      data = result.contents
      expect(String data).to.be.equal reqData
      done()
      return
    else
      result.contents.pipe es.wait (err, data) ->
        expect(String data).to.be.equal reqData
        done()
        return


describe 'gulp-expirer', ->

  describe 'Buffer input', ->
    file1 = null
    exp1 = null
    before ->
      file1 = new gutil.File
        contents: fs.readFileSync path1
        path: path1
      exp1 = expirer tt: 3

    it 'should pass unmodified', (done) ->
      stream = exp1.scan()
      checkStreamData stream, data1, done

      stream.write file1
      stream.end()

    it 'should have correct hash', ->
      expect(exp1._hashes[path1]).to.be.equal hash1


  describe 'Stream input', ->
    file1 = null
    exp1 = null
    before ->
      file1 = new gutil.File
        contents: fs.createReadStream path1
        path: path1
      exp1 = expirer tt: 3

    it 'should pass unmodified', (done) ->
      stream = exp1.scan()
      checkStreamData stream, data1, done

      stream.write file1
      stream.end()

    it 'should have correct hash', ->
      expect(exp1._hashes[path1]).to.be.equal hash1


