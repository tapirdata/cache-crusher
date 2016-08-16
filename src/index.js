import path from 'path';
import _ from 'lodash';
import stream from 'readable-stream';
import streamHasher from 'stream-hasher';
import streamReplacer from 'stream-replacer';

import resolverFactory from './resolver';
import mapperFactory from './mapper';
import catalogFactory from './extractor-catalog';


class Crusher {

  constructor(options = {}) {
    this.setDebug(options.debug);
    this.setEnabled(options.enabled);
    this.cwd = options.cwd || process.cwd();
    if (typeof options.getTagger === 'function') {
      this.getTagger = options.getTagger;
    }
    if (typeof options.getExtractor === 'function') {
      this.getExtractor = options.getExtractor;
    }

    const resolverOptions = _.merge({}, this.constructor.defaultResolverOptions, options.resolver);
    this.resolver = resolverOptions._ || resolverFactory(resolverOptions);

    const mapperOptions = _.merge({}, this.constructor.defaultMapperOptions, options.mapper);
    this.mapper = mapperOptions._ || mapperFactory(mapperOptions);
    this.hasherOptions = _.merge({}, this.constructor.defaultHasherOptions, options.hasher);

    const extractorOptions = _.merge({}, this.constructor.defaultExtractorOptions, options.extractor);
    if (!extractorOptions.catalog) {
      extractorOptions.catalog = catalogFactory();
    }
    this.extractorOptions = extractorOptions;
  }

  setEnabled(enabled) {
    return this.enabled = enabled !== false;
  }

  setDebug(debug) {
    if (!debug) {
      debug = function() {};
    } else if (typeof debug !== 'function') {
      debug = console.error;
    }
    return this.debug = debug;
  }

  getTagger(options) {
    options = options || {};
    if (typeof options._ === 'function') {
      return options._;
    }
    if (options.relativeBase != null) {
      return file => path.join(options.relativeBase, file.relative);
    } else {
      const base = (options.base != null) ? options.base : this.cwd;
      return file => path.relative(base, file.path);
    }
  }

  getExtractor(file) {
    const { catalog } = this.extractorOptions;
    return catalog.getExtractor(file, this.extractorOptions);
  }

  pushOptioner(tagger, options, file) {
    const tag = tagger(file);
    const hit = this.mapper.getTagHit(tag);
    this.debug("crusher.pushOptioner: tag='%s' hit=%s", tag, hit);
    if (hit == null) {
      return {};
    }
    return hit.getHasherOptions(this.hasherOptions);
  }

  pullOptioner(options, file) {
    const extractor = this.getExtractor(file);
    if (!extractor) {
      console.warn(`no extractor for file '${file.path}'`);
      return {pattern: null};
    }
    return {
      pattern: extractor.getPattern(),
      substitute: (match, originTag, done) => {
        this.debug("crusher.puller: originTag='%s' match='%s'", originTag, match[0]);
        const parts = extractor.split(match);
        const hit = this.mapper.getUrlHit(parts.path);
        this.debug("crusher.puller (substitute): url='%s' hit=%s", parts.path, hit);
        if (hit == null) {
          done();
        }
        return this.resolver.pull(hit.getTag(), originTag, (err, result) => {
          if (err) {
            done(err);
          }
          let replacement;
          if (result.tag != null) {
            const newUrl = hit.getUrl(result.tag);
            replacement = parts.preamble + newUrl + parts.query + parts.postamble;
            this.debug("crusher.puller (substitute): newUrl='%s'", newUrl);
          } else {
            const hasherOptions = hit.getHasherOptions(this.hasherOptions);
            if (hasherOptions != null) {
              const { append } = hasherOptions;
              if (append != null) {
                let newQuery = parts.query;
                if (newQuery) {
                  newQuery += '&';
                } else {
                  newQuery += '?';
                }
                let rev;
                if (_.isFunction(append)) {
                  rev = append(result.digest);
                } else if (_.isString(append)) {
                  rev = append + '=' + result.digest;
                } else {
                  rev = result.digest;
                }
                newQuery += rev;
                replacement = parts.preamble + parts.path + newQuery + parts.postamble;
              }
            }
          }
          this.debug("crusher.puller (substitute): replacement='%s'", replacement);
          done(null, replacement);
        }
        );
      }
    };
  }

  pusher(options) {
    if (!this.enabled) {
      return new stream.PassThrough({objectMode: true});
    }
    options = options || {};
    const { resolver, debug } = this;
    const tagger = this.getTagger(options.tagger);
    return streamHasher({
      tagger,
      optioner: this.pushOptioner.bind(this, tagger, options)
    })
    .on('digest', function(digest, oldTag, newTag) {
      debug("cusher.pusher: tag='%s'", oldTag);
      return resolver.push(oldTag, null, {digest, tag: newTag});
    }
    );
  }

  puller(options) {
    if (!this.enabled) {
      return new stream.PassThrough({objectMode: true});
    }
    return streamReplacer({
      tagger: this.getTagger(),
      optioner: this.pullOptioner.bind(this, options)
    });
  }
}


Object.assign(Crusher, {
  defaultResolverOptions: {timeout: 10000},
  defaultMapperOptions: {},
  defaultExtractorOptions: {urlBase: '/static/'},
  defaultHasherOptions: {
    rename: 'postfix',
    digestLength: 8
  },
});

let factory = options => new Crusher(options);
factory.Crusher = Crusher;

export default factory;
