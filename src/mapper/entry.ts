import * as _ from "lodash"
import * as minimatch from "minimatch"
import * as path from "path"
import * as util from "util"

import { EntryOptions } from "../options"

function ensureEndSlash(p: string) {
  if (p[p.length - 1] === "/") {
    return p
  } else {
    return p + "/"
  }
}

const escapeRegExp = (s: string) => s.replace(/[-\/\\^$*+?.()|[\]{}]/g, "\\$&")
  .replace(/(\\\\|\\\/)/g, "[\\\\|\/]")

export class Entry {

  public hasherOptions: any
  protected globs: any
  protected globOptions: any
  protected crushOptions: any
  protected tagRoot: string
  protected urlRoot: string
  protected tagPattern: RegExp
  protected urlPattern: RegExp
  private mms: any

  constructor(options: EntryOptions) {
    this.globs = options.globs
    this.globOptions = options.globOptions
    this.crushOptions = options.crushOptions
    this.tagRoot = ensureEndSlash(options.tagRoot)
    this.urlRoot = ensureEndSlash(options.urlRoot)
    this.urlPattern = new RegExp(`^${escapeRegExp(this.urlRoot)}(.*)`)
    this.tagPattern = new RegExp(`^${escapeRegExp(this.tagRoot)}(.*)`)
    this._setupMms()
  }

  public checkGlob(rel: string) {
    const mms = this.mms
    if (mms == null) {
      return true
    }
    let ok = null
    for (const mm of mms) {
      if (ok === null || ok === mm.negate) {
        ok = mm.match(rel)
      }
    }
    return ok
  }

  public checkRel(rel: string) {
    return this.checkGlob(rel)
  }

  public getUrlRel(url: string) {
    const match = this.urlPattern.exec(url)
    if (match != null) {
      return match[1]
    }
  }

  public getTagRel(tag: string) {
    const match = this.tagPattern.exec(tag)
    if (match != null) {
      return match[1]
    }
  }

  public getTag(rel: string) {
    return path.join(this.tagRoot, rel)
  }

  public getUrl(rel: string) {
    return path.join(this.urlRoot, rel)
      .replace(/\\/g, "/")
  }

  public toString() {
    return util.format(
        "Entry({urlRoot='%s', tagRoot='%s', globs=%s, crushOptions=%j})",
        this.urlRoot,
        this.tagRoot,
        this.globs,
        this.crushOptions,
    )
  }

  protected _setupMms() {
    let { globs } = this
    let mms: any = null
    if (globs) {
      mms = []
      if (!_.isArray(globs)) {
        globs = [globs]
      }
      for (const glob of globs) {
        const mm = new minimatch.Minimatch(glob, this.globOptions)
        mms.push(mm)
      }
      if (mms.length === 0) {
        mms = null
      }
    }
    this.mms = mms
  }

}
