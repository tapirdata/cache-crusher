import _ from "lodash"
import util from "util"

import { Entry } from "./entry"

export class Hit {

  protected entry: Entry
  protected rel: any

  constructor(entry: Entry, rel: any) {
    this.entry = entry
    this.rel = rel
  }

  public getHasherOptions(options: any) {
    if (this.entry.hasherOptions) {
      options = _.merge({}, options, this.entry.hasherOptions)
    }
    return options
  }

  public getTag(url?: string) {
    const rel = (url != null) ? this.entry.getUrlRel(url) : this.rel
    return this.entry.getTag(rel)
  }

  public getUrl(tag: string) {
    const rel = (tag != null) ? this.entry.getTagRel(tag) : this.rel
    return this.entry.getUrl(rel)
  }

  public toString(): string {
    return util.format("Hit({entry=%s, rel=%s})", this.entry, this.rel)
  }
}
