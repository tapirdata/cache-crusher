import fs = require("fs")
import path = require("path")
import _ = require("lodash")
import stream = require("stream")
import File = require("vinyl")
import vinylFs = require("vinyl-fs")
import { assert, expect } from "chai"
import vinylTapper from "vinyl-tapper"
import crusherFactory from "../src/index"
import { Crusher } from "../src/index"
import { Cb } from "../src/options"
import glob = require ("glob")

interface BufferMap { [p: string]: Buffer }
interface BufferFileMap { [p: string]: { buffer: Buffer, file: File} }

function readTree(srcRoot: string, srcBase: string, done: Cb) {
  glob(srcRoot + "/**/*", {nodir: true}, (err: any, srcPaths: string[]) => {
    if (err) {
      done(err)
    } else {
      const promises = srcPaths.map((srcPath: string) => new Promise((resolve, reject) => {
        return fs.readFile(srcPath, (readErr: any, srcBuffer: Buffer) => {
          if (readErr) {
            reject(err)
          } else {
            resolve(srcBuffer)
          }
        })
      }))
      Promise.all(promises)
        .then((srcBuffers: Buffer[]) => {
          const results: BufferMap = {}
          srcPaths.map((srcPath, idx) => {
            results[path.relative(srcBase, srcPath)] = srcBuffers[idx]
          })
          done(null, results)
        })
    }
  })
}

function compareResultsExps(results: BufferFileMap, exps: BufferMap) {
  const misses: string[] = []
  const extras: string[] = []
  for (const p in exps) {
    if (results[p] == null) {
      misses.push(p)
    }
  }
  for (const p in results) {
    if (!exps[p]) {
      extras.push(p)
    }
  }
  assert(misses.length === 0 && extras.length === 0, (() => {
    const parts: string[] = []
    if (misses.length) {
      parts.push((_.map(misses, (s) => `'${s}'`)).join(", ") + " missing")
    }
    if (extras.length) {
      parts.push((_.map(extras, (s) => `'${s}'`)).join(", ") + " superfluous")
    }
    return `Paths differ: ${parts.join("; ")}`
  }) as any)

  for (const p of Object.keys(results)) {
    const result = results[p]
    const expBuffer = exps[p]
    expect(result.buffer.toString()).to.be.equal(expBuffer.toString("utf8"))
  }
}

class PullStringReplacer extends stream.Transform {

  protected crusher: Crusher

  constructor(crusher: Crusher, options = {}) {
    super({ objectMode: true })
    this.crusher = crusher
  }

  public _transform(file: File, enc: string, next: Cb) {
    assert(file.isBuffer())
    const text = String(file.contents)
    this.crusher.pullString(text, file)
      .then((pulledText) => {
        file.contents = new Buffer(pulledText, enc)
        next(null, file)
      })
      .catch((err) => {
        next(err)
      })
  }

}

const fixtureDir = path.join(__dirname, "fixtures")

function makeTests(title: string, options: any) {

  const pushSrcDir = path.join(fixtureDir, options.srcDir, "push")
  const pullSrcDir = path.join(fixtureDir, options.srcDir, "pull")
  const pushExpDir = path.join(fixtureDir, options.expDir, "push")
  const pullExpDir = path.join(fixtureDir, options.expDir, "pull")

  const defaultCounterparts = [
    {
      urlRoot: "/app",
      tagRoot: path.relative(__dirname, pushSrcDir),
      globs: ["*.css", "*.js"],
      globOptions: { matchBase: true },
    },
  ]

  const defaultCrusherOptions = {
    cwd: __dirname,
    extractor: {
      urlBase: "/app/",
    },
    mapper: {
      counterparts: defaultCounterparts,
    },
    resolver: {
      timeout: 1000,
    },
    hasher: {
      rename: "postfix",
    },
  }

  const pushResults: BufferFileMap = {}
  const pullResults: BufferFileMap = {}

  const pushTapper = vinylTapper({
    provideBuffer: true,
    terminate: true,
  })
  pushTapper.on("tap", (file: File, buffer: Buffer) => {
    pushResults[file.relative] = {
      file,
      buffer,
    }
  })

  const pullTapper = vinylTapper({
    provideBuffer: true,
    terminate: true,
  })
  pullTapper.on("tap", (file: File, buffer: Buffer) =>
    pullResults[file.relative] = {
      file,
      buffer,
    },

  )

  let pushExps: BufferMap
  let pullExps: BufferMap

  function readExps(cb: Cb) {
    readTree(pushExpDir, pushExpDir, (err, results) => {
      pushExps = results
      if (err) {
        cb(err)
        return
      }
      return readTree(pullExpDir, pullExpDir, (readErr, readResults) => {
        pullExps = readResults
        if (readErr) {
          cb(readErr)
          return
        }
        return cb()
      })
    })
  }

  const pushOptions = options.push || {}
  const pullOptions = options.pull || {}

  describe(title, () => {

    let crusher: Crusher

    before((done: Cb) => {
      readExps((err: any) => {
        if (err) {
          done(err)
          return
        }

        let streamCount = 2
        const streamDone = () => {
          if (--streamCount === 0) {
            done()
          }
        }

        let crusherOptions = defaultCrusherOptions
        if (options.crusher) {
          crusherOptions = _.merge({}, crusherOptions, options.crusher)
        }
        crusher = crusherFactory(crusherOptions)

        const runPush = () => {
          let pushWell = vinylFs.src("**/*.*", {
            cwd: pushSrcDir,
            buffer: pushOptions.useBuffer,
          })
          pushWell = pushWell.pipe(crusher.pusher())
          return pushWell
            .pipe(pushTapper)
            .on("end", streamDone)
        }
        setTimeout(runPush, pushOptions.delay)

        const runPull = () => {
          let pullWell = vinylFs.src("**/*.*", {
            cwd: pullSrcDir,
            buffer: pullOptions.useBuffer,
          })
          if (pullOptions.asString) {
            pullWell = pullWell.pipe(new PullStringReplacer(crusher))
          } else {
            pullWell = pullWell.pipe(crusher.puller())
          }
          return pullWell
            .pipe(pullTapper)
            .on("end", streamDone)
        }
        setTimeout(runPull, pullOptions.delay)

      })
    })

    it("should write the expected push files", () => {
      compareResultsExps(pushResults, pushExps)
    })
    it("should write the expected pull files", () => {
      compareResultsExps(pullResults, pullExps)
    })
  })
}

describe("cache-crusher", () => {

  makeTests("Simple postfix", {
    srcDir: "simple-src",
    expDir: "simple-exp-postfix",
  })

  makeTests("Simple postfix with pull buffer", {
    srcDir: "simple-src",
    expDir: "simple-exp-postfix",
    pull: {
      useBuffer: true,
    },
  })

  makeTests("Simple postfix with push buffer", {
    srcDir: "simple-src",
    expDir: "simple-exp-postfix",
    push: {
      useBuffer: true,
    },
  })

  makeTests("Simple postfix with push delay", {
    srcDir: "simple-src",
    expDir: "simple-exp-postfix",
    push: {
      delay: 500,
    },
  })

  makeTests("Simple postfix with pull delay", {
    srcDir: "simple-src",
    expDir: "simple-exp-postfix",
    pull: {
      delay: 500,
    },
  })

  makeTests("Simple append", {
    srcDir: "simple-src",
    expDir: "simple-exp-append",
    crusher: {
      hasher: {
        rename: false,
        append: "rev",
      },
    },
  })

  makeTests("Simple postfix with pullString", {
    srcDir: "simple-src",
    expDir: "simple-exp-postfix",
    pull: {
      asString: true,
    },
  })

})
