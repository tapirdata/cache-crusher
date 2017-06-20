import { Cb, ResolverOptions } from "./options"
import { TimeoutError } from "./timeout-error"

export interface ResolverEntry {
  err: any
  data: any
  queue: any[]
  timer: NodeJS.Timer | null
  resolved?: boolean
}

export class Resolver {

  public map: { [tag: string]: ResolverEntry }
  public timeout?: number

  constructor(options: ResolverOptions = {}) {
    this.map = {}
    this.timeout = options.timeout
  }

  public getEntry(tag: string): ResolverEntry {
    return this.map[tag]
  }

  public createEntry(tag: string, err?: any, data?: any) {
    return this.map[tag] = {
      err,
      data,
      queue: [],
      timer: null,
    }
  }

  public resolveEntry(entry: ResolverEntry, err: any, data: any) {
    if (entry.timer != null) {
      clearTimeout(entry.timer)
      entry.timer = null
    }
    entry.err = err
    entry.data = data
    while (entry.queue.length > 0) {
      const done = entry.queue.shift()
      done(entry.err, entry.data)
    }
    entry.resolved = true
  }

  public pull(tag: string, originTag: string, done: Cb) {
    let entry = this.map[tag]
    if (entry != null) {
      if (entry.resolved) {
        done(entry.err, entry.data)
        return
      }
    } else {
      entry = this.createEntry(tag)
    }
    entry.queue.push(done)
    if (this.timeout != null) {
      const timerFn = () => this.resolveEntry(entry, new TimeoutError(tag, originTag, this.timeout), undefined)
      entry.timer = setTimeout(timerFn, this.timeout)
    }
  }

  public push(tag: string, err: any, data: any) {
    let entry = this.map[tag]
    if (entry != null) {
      if (entry.resolved) {
        if (!entry.err) {
          throw new Error(`duplicate tag: '${tag}'`)
        }
      } else {
        this.resolveEntry(entry, err, data)
      }
    } else {
      entry = this.createEntry(tag, err, data)
      entry.resolved = true
    }
  }
}

export interface Factory {
  (options: ResolverOptions): Resolver
  Resolver: typeof Resolver
  TimeoutError: typeof TimeoutError
}

const factory = ((options: ResolverOptions) => {
  return new Resolver(options)
}) as Factory
factory.Resolver = Resolver
factory.TimeoutError = TimeoutError

export default factory
