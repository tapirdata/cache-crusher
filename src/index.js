import path from 'path';
import _ from 'lodash';
import stream from 'readable-stream';
import streamHasher from 'stream-hasher';
import streamReplacer from 'stream-replacer';

import resolverFactory from './resolver';
import mapperFactory from './mapper';
import catalogFactory from './extractor-catalog';


class Crusher {

  constructor(options) {
    options = options || {};

    this.setDebug(options.debug);
    this.setEnabled(options.enabled);
    this.cwd = options.cwd || process.cwd();
    if (typeof options.getTagger === 'function') {
      this.getTagger = options.getTagger;
    }
    if (typeof options.getExtractor === 'function') {
      this.getExtractor = options.getExtractor;
    }

    let resolverOptions = _.merge({}, this.constructor.defaultResolverOptions, options.resolver);
    this.resolver = resolverOptions._ || resolverFactory(resolverOptions);

    let mapperOptions = _.merge({}, this.constructor.defaultMapperOptions, options.mapper);
    this.mapper = mapperOptions._ || mapperFactory(mapperOptions);
    this.hasherOptions = _.merge({}, this.constructor.defaultHasherOptions, options.hasher);

    let extractorOptions = _.merge({}, this.constructor.defaultExtractorOptions, options.extractor);
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
      let base = (options.base != null) ? options.base : this.cwd;
      return file => path.relative(base, file.path);
    }
  }

  getExtractor(file) {
    let { catalog } = this.extractorOptions;
    return catalog.getExtractor(file, this.extractorOptions);
  }

  pushOptioner(tagger, options, file) {
    let tag = tagger(file);
    let hit = this.mapper.getTagHit(tag);
    this.debug("crusher.pushOptioner: tag='%s' hit=%s", tag, hit);
    if (hit == null) {
      return {};
    }
    return hit.getHasherOptions(this.hasherOptions);
  }

  pullOptioner(options, file) {
    let self = this;
    let extractor = this.getExtractor(file);
    if (!extractor) {
      console.warn(`no extractor for file '${file.path}'`);
      return {pattern: null};
    }
    return {
      pattern: extractor.getPattern(),
      substitute(match, originTag, done) {
        self.debug("crusher.puller: originTag='%s' match='%s'", originTag, match[0]);
        let parts = extractor.split(match);
        let hit = self.mapper.getUrlHit(parts.path);
        self.debug("crusher.puller (substitute): url='%s' hit=%s", parts.path, hit);
        if (hit == null) {
          done();
          return;
        }
        return self.resolver.pull(hit.getTag(), originTag, function(err, result) {
          if (err) {
            done(err);
            return;
          }
          if (result.tag != null) {
            let newUrl = hit.getUrl(result.tag);
            var replacement = parts.preamble + newUrl + parts.query + parts.postamble;
            self.debug("crusher.puller (substitute): newUrl='%s'", newUrl);
          } else {
            let hasherOptions = hit.getHasherOptions(self.hasherOptions);
            if (hasherOptions != null) {
              let { append } = hasherOptions;
              if (append != null) {
                let newQuery = parts.query;
                if (newQuery) {
                  newQuery += '&';
                } else {
                  newQuery += '?';
                }
                if (_.isFunction(append)) {
                  var rev = append(result.digest);
                } else if (_.isString(append)) {
                  var rev = append + '=' + result.digest;
                } else {
                  var rev = result.digest;
                }
                newQuery += rev;
                var replacement = parts.preamble + parts.path + newQuery + parts.postamble;
              }
            }
          }
          self.debug("crusher.puller (substitute): replacement='%s'", replacement);
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
    let { resolver } = this;
    let tagger = this.getTagger(options.tagger);
    let { debug } = this;
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
