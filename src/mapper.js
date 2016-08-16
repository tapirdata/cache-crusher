import util from 'util';
import path from 'path';
import _ from 'lodash';
import minimatch from 'minimatch';

const escapeRegExp = s => s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');


function ensureEndSlash(p) {
  if (p[p.length - 1] === '/') {
    return p;
  } else {
    return p + '/';
  }
};


class Entry {
  constructor(options) {
    this.globs = options.globs;
    this.globOptions = options.globOptions;
    this.crushOptions = options.crushOptions;
    this.tagRoot = ensureEndSlash(options.tagRoot);
    this.urlRoot = ensureEndSlash(options.urlRoot);
    this.urlPattern = new RegExp(`^${escapeRegExp(this.urlRoot)}(.*)`);
    this.tagPattern = new RegExp(`^${escapeRegExp(this.tagRoot)}(.*)`);
    this._setupMms();
  }

  _setupMms() {
    let { globs } = this;
    let mms = null;
    if (globs) {
      mms = [];
      if (!_.isArray(globs)) {
        globs = [globs];
      }
      for (let i = 0; i < globs.length; i++) {
        let glob = globs[i];
        let mm = new minimatch.Minimatch(glob, this.globOptions);
        mms.push(mm);
      }
      if (mms.length === 0) {
        mms = null;
      }
    }
    this._mms = mms;
  }

  checkGlob(rel) {
    let mms = this._mms;
    if (mms == null) {
      return true;
    }
    let ok = null;
    for (let i = 0; i < mms.length; i++) {
      let mm = mms[i];
      if (ok === null || ok === mm.negate) {
        ok = mm.match(rel);
      }
    }
    return ok;
  }

  checkRel(rel) {
    return this.checkGlob(rel);
  }

  getUrlRel(url) {
    let match = this.urlPattern.exec(url);
    if (match != null) {
      return match[1];
    }
  }

  getTagRel(tag) {
    let match = this.tagPattern.exec(tag);
    if (match != null) {
      return match[1];
    }
  }

  getTag(rel) {
    return path.join(this.tagRoot, rel);
  }

  getUrl(rel) {
    return path.join(this.urlRoot, rel);
  }

  toString() {
    return util.format("Entry({urlRoot='%s', tagRoot='%s', globs=%s, crushOptions=%j})", this.urlRoot, this.tagRoot, this.globs, this.crushOptions);
  }
}


class Hit {
  constructor(entry, rel) {
    this.entry = entry;
    this.rel = rel;
  }

  getHasherOptions(options) {
    if (this.entry.hasherOptions) {
      options = _.merge({}, options, this.entry.hasherOptions);
    }
    return options;  
  }

  getTag(url) {
    let rel = (url != null) ? this.entry.getUrlRel(url) : this.rel;
    return this.entry.getTag(rel);
  }

  getUrl(tag) {  
    let rel = (tag != null) ? this.entry.getTagRel(tag) : this.rel;
    return this.entry.getUrl(rel);
  }

  toString() {
    return util.format("Hit({entry=%s, rel=%s})", this.entry, this.rel);
  }
}


class Mapper {

  constructor(options) {
    options = options || {};
    let entries = [];
    let iterable = options.counterparts || [];
    for (let i = 0; i < iterable.length; i++) {
      let cp = iterable[i];
      entries.push(new Entry(cp));
    }
    this.entries = entries;
  }

  getUrlHit(url) {
    for (let i = 0; i < this.entries.length; i++) {
      let entry = this.entries[i];
      let rel = entry.getUrlRel(url);
      if ((rel != null) && entry.checkRel(rel)) {
        return new Hit(entry, rel);
      }
    }
  }

  getTagHit(tag) {
    for (let i = 0; i < this.entries.length; i++) {
      let entry = this.entries[i];
      let rel = entry.getTagRel(tag);
      if ((rel != null) && entry.checkRel(rel)) {
        return new Hit(entry, rel);
      }
    }
  }
}


let factory = options => new Mapper(options);

factory.Mapper = Mapper;

export default factory;



