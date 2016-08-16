import fs from 'fs';
import path from 'path';
import _ from 'lodash';

class ExtractorCatalog {

  constructor(options = {}) {
    this._classes = {};
    this._handles = {};
    let { scan } = options;
    if (scan !== false) {
      if (_.isString(scan)) {
        var scanDir = scan;
      } else {
        var scanDir = path.join(__dirname, './extractors');
      }
      this.scanExtractors(scanDir, options);
    }
  }

  scanExtractors(scanDir, options) {
    let fileNames = fs.readdirSync(scanDir);
    for (let i = 0; i < fileNames.length; i++) {
      let fileName = fileNames[i];
      let extractorPath = path.join(scanDir, fileName);
      try {
        var Extractor = require(extractorPath).default;
      } catch (err) {
        console.log(`cannnot require extractor '${extractorPath}'`, err);
        continue;
      }
      if (typeof Extractor === 'function' && (Extractor.handle != null)) {
        this.registerClass(Extractor, options);
      }
    }    
  }

  registerExts(handle, exts) {
    if (exts) {
      if (!_.isArray(exts)) {
        exts = [exts];
      }
      return exts.map((ext) =>
        this._handles[ext] = handle);
    }
  }

  registerClass(Extractor, options) {
    options = options || {};
    this._classes[Extractor.handle] = Extractor;
    if (options.withExts !== false) {
      return this.registerExts(Extractor.handle, Extractor.exts);
    }
  }

  getClass(handle) {
    return this._classes[handle];
  }

  getHandle(ext) {
    return this._handles[ext];
  }

  getExtractor(file, options) {
    let ext = path.extname(file.path);
    let handle = this.getHandle(ext);
    let Extractor = this.getClass(handle);
    if (Extractor != null) {
      return new Extractor(options);
    }
  }
}


let factory = options => new ExtractorCatalog(options);
factory.ExtractorCatalog = ExtractorCatalog;

export default factory;





