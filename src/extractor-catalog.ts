import fs = require("fs")
import path = require("path")
import File = require("vinyl")
import _ = require("lodash")
import Extractor from "./extractors/extractor"
import { CatalogOptions, ExtractorOptions } from "./options"

export class ExtractorCatalog {

  protected allClasses: {[handle: string]: any}
  protected allHandles: {[ext: string]: any}

  constructor(options: CatalogOptions = {}) {
    this.allClasses = {}
    this.allHandles = {}
    const { scan } = options
    if (scan !== false) {
      let scanDir: string
      if (_.isString(scan)) {
        scanDir = scan
      } else {
        scanDir = path.join(__dirname, "./extractors")
      }
      this.scanExtractors(scanDir, options)
    }
  }

  public scanExtractors(scanDir: string, options: CatalogOptions) {
    const fileNames = fs.readdirSync(scanDir)
    for (const fileName of fileNames) {
      const extractorPath = path.join(scanDir, fileName)
      let ExtractorCls
      try {
        ExtractorCls = require(extractorPath).default
      } catch (err) {
        // tslint:disable-next-line: no-console
        console.log(`cannnot require extractor '${extractorPath}'`, err)
        continue
      }
      if (typeof ExtractorCls === "function" && (ExtractorCls.handle != null)) {
        this.registerClass(ExtractorCls, options)
      }
    }
  }

  public registerExts(handle: string, exts: string[] | string) {
    if (exts) {
      if (!_.isArray(exts)) {
        exts = [exts]
      }
      return exts.map((ext) =>
        this.allHandles[ext] = handle)
    }
  }

  public registerClass(ExtractorCls: typeof Extractor, options: CatalogOptions = {}) {
    this.allClasses[ExtractorCls.handle] = ExtractorCls
    if (options.withExts !== false) {
      return this.registerExts(ExtractorCls.handle, ExtractorCls.exts)
    }
  }

  public getClass(handle: string) {
    return this.allClasses[handle]
  }

  public getHandle(ext: string) {
    return this.allHandles[ext]
  }

  public getExtractor(file: File, options: any): Extractor | undefined {
    const ext = path.extname(file.path)
    const handle = this.getHandle(ext)
    const ExtractorCls = this.getClass(handle)
    if (ExtractorCls != null) {
      return new ExtractorCls(options)
    }
  }
}

export interface Factory {
  (options: CatalogOptions): ExtractorCatalog
  ExtractorCatalog: typeof ExtractorCatalog
}

const factory = ((options) => new ExtractorCatalog(options)) as Factory
factory.ExtractorCatalog = ExtractorCatalog

export default factory
