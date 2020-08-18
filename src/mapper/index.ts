import { MapperOptions, ResolverOptions } from "../options"
import { Entry } from "./entry"
import { Hit } from "./hit"

export class Mapper {

  public entries: Entry[]

  constructor(options: MapperOptions) {
    options = options || {}
    const entries: Entry[] = []
    const iterable = options.counterparts || []
    for (const cp of iterable) {
      entries.push(new Entry(cp))
    }
    this.entries = entries
  }

  public getUrlHit(url: string) {
    for (const entry of this.entries) {
      const rel = entry.getUrlRel(url)
      if ((rel != null) && entry.checkRel(rel)) {
        return new Hit(entry, rel)
      }
    }
  }

  public getTagHit(tag: string): Hit | undefined {
    for (const entry of this.entries) {
      const rel = entry.getTagRel(tag)
      if ((rel != null) && entry.checkRel(rel)) {
        return new Hit(entry, rel)
      }
    }
  }
}

export interface Factory {
  (options: MapperOptions): Mapper
  Mapper: typeof Mapper
}

const factory = ((options: MapperOptions) => {
  return new Mapper(options)
}) as Factory
factory.Mapper = Mapper

export default factory
