import _ = require("lodash")
import path = require("path")
import stream = require ("stream")
import streamHasher from "stream-hasher"
import { HasherOptions } from "stream-hasher"
import streamReplacer from "stream-replacer"
import File = require("vinyl")

import defaultCatalogFactory from "./default-catalog"
import { Extractor } from "./extractor"
import mapperFactory from "./mapper"
import { Mapper } from "./mapper"
import {
  Cb,
  CrusherOptions,
  ExtractorCatalog,
  ExtractorOptions,
  MapperOptions,
  PullOptions,
  ResolverOptions,
  Tagger,
  TaggerOptions,
} from "./options"
import resolverFactory from "./resolver"
import { Resolver } from "./resolver"

export class Crusher {

  public get defaultResolverOptions() { return { timeout: 10000 } }
  public get defaultMapperOptions() { return {} }
  public get defaultExtractorOptions() { return { urlBase: "/static/" } }
  public get defaultHasherOptions() { return {
    rename: "postfix",
    digestLength: 8,
  } }

  public extractorCatalog: ExtractorCatalog

  protected debug!: (...args: any[]) => void
  protected enabled?: boolean
  protected cwd: string
  // protected resolverOptions: ResolverOptions
  protected hasherOptions: HasherOptions
  protected resolver: Resolver
  protected mapper: Mapper
  protected extractorOptions: ExtractorOptions

  constructor(options: CrusherOptions = {}) {
    this.setDebug(options.debug)
    this.setEnabled(options.enabled)
    this.cwd = options.cwd || process.cwd()
    if (typeof options.getTagger === "function") {
      (this as any).getTagger = options.getTagger
    }
    if (typeof options.getExtractor === "function") {
      (this as any).getExtractor = options.getExtractor
    }

    const resolverOptions: ResolverOptions = _.merge({}, this.defaultResolverOptions, options.resolver)
    this.resolver = resolverOptions._ || resolverFactory(resolverOptions)

    const mapperOptions: MapperOptions = _.merge({}, this.defaultMapperOptions, options.mapper)
    this.mapper = mapperOptions._ || mapperFactory(mapperOptions)
    this.hasherOptions = _.merge({}, this.defaultHasherOptions, options.hasher)

    const extractorOptions: ExtractorOptions = _.merge({}, this.defaultExtractorOptions, options.extractor)
    this.extractorOptions = extractorOptions
    this.extractorCatalog = extractorOptions.catalog || defaultCatalogFactory({})
  }

  public setEnabled(enabled?: boolean) {
    return this.enabled = enabled !== false
  }

  public setDebug(debug: any) {
    if (!debug) {
      debug = () => undefined
    } else if (typeof debug !== "function") {
      debug = console.error
    }
    this.debug = debug
  }

  public getTagger(options: TaggerOptions = {}): Tagger {
    if (typeof options._ === "function") {
      return options._
    }
    if (options.relativeBase != null) {
      return (file: File) => path.join(options.relativeBase as string, file.relative)
    } else {
      const base = (options.base != null) ? options.base : this.cwd
      return (file: File) => path.relative(base, file.path)
    }
  }

  public getExtractor(file: File): Extractor | undefined {
    const catalog = this.extractorCatalog
    if (catalog) {
      return catalog.getExtractor(file, this.extractorOptions)
    }
  }

  public pushOptioner(tagger: Tagger, options: any, file: File) {
    const tag = tagger(file)
    const hit = this.mapper.getTagHit(tag)
    this.debug("crusher.pushOptioner: tag='%s' hit=%s", tag, hit)
    if (hit == null) {
      return {}
    }
    return hit.getHasherOptions(this.hasherOptions)
  }

  public pullOptioner(options: any, file: File): PullOptions {
    const extractor = this.getExtractor(file)
    if (!extractor) {
      // tslint:disable-next-line: no-console
      console.warn(`no extractor for file '${file.path}'`)
      return { pattern: null } as any
    }
    return {
      pattern: extractor.getPattern(),
      substitute: (match: any, originTag: string, done: Cb) => {
        this.debug("crusher.puller: originTag='%s' match='%s'", originTag, match[0])
        const parts = extractor.split(match)
        const hit = this.mapper.getUrlHit(parts.path)
        this.debug("crusher.puller (substitute): url='%s' hit=%s", parts.path, hit)
        if (hit == null) {
          done()
          return
        }
        return this.resolver.pull(hit.getTag(), originTag, (err: any, result: any) => {
          if (err) {
            done(err)
            return
          }
          let replacement
          if (result.tag != null) {
            const newUrl = hit.getUrl(result.tag)
            replacement = parts.preamble + newUrl + parts.query + parts.postamble
            this.debug("crusher.puller (substitute): newUrl='%s'", newUrl)
          } else {
            const hasherOptions = hit.getHasherOptions(this.hasherOptions)
            if (hasherOptions != null) {
              const { append } = hasherOptions
              if (append != null) {
                let newQuery = parts.query
                if (newQuery) {
                  newQuery += "&"
                } else {
                  newQuery += "?"
                }
                let rev
                if (_.isFunction(append)) {
                  rev = append(result.digest)
                } else if (_.isString(append)) {
                  rev = append + "=" + result.digest
                } else {
                  rev = result.digest
                }
                newQuery += rev
                replacement = parts.preamble + parts.path + newQuery + parts.postamble
              }
            }
          }
          this.debug("crusher.puller (substitute): replacement='%s'", replacement)
          done(null, replacement)
        })
      },
    }
  }

  public pusher(options: { tagger?: any } = {}) {
    if (!this.enabled) {
      return new stream.PassThrough({objectMode: true})
    }
    const { resolver, debug } = this
    const tagger = this.getTagger(options.tagger)
    return streamHasher({
      tagger,
      optioner: this.pushOptioner.bind(this, tagger, options),
    })
    .on("digest", (digest: string, oldTag: string, newTag: string) => {
      debug("cusher.pusher: tag='%s'", oldTag)
      return resolver.push(oldTag, null, {digest, tag: newTag})
    })
  }

  public puller(options = {}) {
    if (!this.enabled) {
      return new stream.PassThrough({objectMode: true})
    }
    return streamReplacer({
      tagger: this.getTagger(),
      optioner: this.pullOptioner.bind(this, options),
    })
  }

  public pullString(source: string, fileinfo: File, pullOptions: any = {}) {
    if (this.enabled) {
      const options = this.pullOptioner(pullOptions, fileinfo)
      if (options.pattern != null) {
        const tagger = this.getTagger()
        const tag: string = tagger(fileinfo)
        let rest: string = source
        const matches: any[] = []
        const strs: string[] = []
        while (true) {
          const match = options.pattern.exec(rest)
          if (match == null) {
            break
          }
          const matchLength = match[0].length
          strs.push(rest.slice(0, match.index))
          matches.push(match)
          rest = rest.slice(match.index + matchLength)
        }
        if (matches.length >  0) {
          const promises: Array<Promise<any>> = []
          for (const match of matches) {
            promises.push(new Promise((resolve, reject) => {
              options.substitute(match, tag, (err: any, replacement: any) => {
                if (err) {
                  reject(err)
                } else {
                  resolve(replacement)
                }
              })
            }))
          }
          return Promise.all(promises)
          .then((replacements) => {
            let result = ""
            for (let idx = 0; idx < matches.length; ++idx) {
              result += strs[idx]
              let replacement = replacements[idx]
              if (replacement == null) {
                replacement = matches[idx][0]
              }
              result += replacement
            }
            result += rest
            return result
          })
        }
      }
    }
    return Promise.resolve(source)
  }

}

export interface Factory {
  (options: CrusherOptions): Crusher
  Crusher: typeof Crusher
}

const factory = ((options: CrusherOptions) => {
  return new Crusher(options)
}) as Factory

factory.Crusher = Crusher

export default factory
export { Extractor }
