import { HasherOptions } from "stream-hasher"
import { ReplacerOptions } from "stream-replacer"
import File = require("vinyl")

import { Extractor } from "./extractor"
import { Mapper } from "./mapper"
import { Resolver } from "./resolver"

export type Cb = (err?: any, val?: any) => void
export type Tagger = (file: File) => string
export type TaggerGetter = (options?: any) => Tagger

export interface CatalogOptions {
  scan?: boolean | string
  withExts?: boolean
}

export interface TaggerOptions {
  _?: Tagger
  relativeBase?: string
  base?: string
}

export interface CrusherOptions {
  debug?: (...args: any[]) => void
  enabled?: boolean
  cwd?: string
  getTagger?: TaggerGetter
  getExtractor?: any
  resolver?: ResolverOptions
  mapper?: MapperOptions
  hasher?: HasherOptions
  replacer?: ReplacerOptions
  extractor?: ExtractorOptions
}

export interface PullOptions {
  pattern?: RegExp
  substitute: (match: any, tag: string, cb: Cb) => any
}

export interface ResolverOptions {
  _?: Resolver
  timeout?: number
}

export interface EntryOptions {
  globs?: any
  globOptions?: any
  crushOptions?: any
  tagRoot: string
  urlRoot: string
}

export interface MapperOptions {
  _?: Mapper
  counterparts?: any[]
}

export interface ExtractorCatalog {
  registerClass(ExtractorCls: typeof Extractor, options: any): void
  registerExts(handle: string, exts: string[] | string): void
  getExtractor(file: File, options: any): Extractor | undefined
}

export interface ExtractorOptions {
  urlBase?: string
  partBrick?: string
  catalog?: ExtractorCatalog
}
