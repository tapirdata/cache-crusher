import fs from 'fs';
import path from 'path';
import _ from 'lodash';

class ExtractorCatalog {

  constructor(options = {}) {
    this._classes = {};
    this._handles = {};
    const { scan } = options;
    if (scan !== false) {
      let scanDir;
      if (_.isString(scan)) {
        scanDir = scan;
      } else {
        scanDir = path.join(__dirname, './extractors');
      }
      this.scanExtractors(scanDir, options);
    }
  }

  scanExtractors(scanDir, options) {
    const fileNames = fs.readdirSync(scanDir);
    for (const fileName of fileNames) {
      const extractorPath = path.join(scanDir, fileName);
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
    const ext = path.extname(file.path);
    const handle = this.getHandle(ext);
    const Extractor = this.getClass(handle);
    if (Extractor != null) {
      return new Extractor(options);
    }
  }
}


const factory = options => new ExtractorCatalog(options);
factory.ExtractorCatalog = ExtractorCatalog;

export default factory;





