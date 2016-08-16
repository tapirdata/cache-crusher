import fs from 'fs';
import path from 'path';
import _ from 'lodash';
import vinylFs from 'vinyl-fs';
import vinylTapper from 'vinyl-tapper';
import { expect, assert } from 'chai';
import cacheCrusher from '../src/index';
import walk from 'walk';


let readTree = function(srcRoot, srcBase, done) {
  let walker = walk.walk(srcRoot);
  let results = {};

  walker.on('file', function(src, stat, next) {
    let srcPath = path.join(src, stat.name);
    return fs.readFile(srcPath, function(err, srcBuffer) {
      if (err) {
        next(err);
        return;
      }
      results[path.relative(srcBase, srcPath)] = srcBuffer;
      next();
    }
    );
  }
  );

  return walker.on('end', () => done(null, results)
  );
};


let compareResultsExps = function(results, exps) {
  let misses = [];
  let extras = [];
  for (var p in exps) {
    if (results[p] == null) {
      misses.push(p);
    }
  }
  for (p in results) {
    if (!exps[p]) {
      extras.push(p);
    }
  }
  assert(misses.length === 0 && extras.length === 0, function() {
    let parts = [];
    if (misses.length) {
      parts.push((_.map(misses, s => `'${s}'`)).join(', ') + ' missing');
    }
    if (extras.length) {
      parts.push((_.map(extras, s => `'${s}'`)).join(', ') + ' superfluous');
    }
    return `Paths differ: ${parts.join('; ')}`;
  }
  );

  for (p in results) {
    let result = results[p];
    let expBuffer = exps[p];
    expect(result.buffer.toString('utf8')).to.be.equal(expBuffer.toString('utf8'));
  }  
};


let fixtureDir = path.join(__dirname, 'fixtures');

let makeTests = function(title, options) {

  let pushSrcDir = path.join(fixtureDir, options.srcDir, 'push');
  let pullSrcDir = path.join(fixtureDir, options.srcDir, 'pull');
  let pushExpDir = path.join(fixtureDir, options.expDir, 'push');
  let pullExpDir = path.join(fixtureDir, options.expDir, 'pull');

  let defaultCounterparts = [
    {
      urlRoot: '/app',
      tagRoot: path.relative(__dirname, pushSrcDir),
      // globs: ['**/*.css', '**/*.js']
      globs: ['*.css', '*.js'],
      globOptions: { matchBase: true
    }
    }
  ];

  let defaultCrusherOptions = {
    cwd: __dirname,
    extractor: {
      urlBase: '/app/'
    },
    mapper: {
      counterparts: defaultCounterparts
    },
    resolver: {
      timeout: 1000
    },
    hasher: {
      rename: 'postfix'
    }
  };
      // append: 'momo'

  let pushResults = {};
  let pullResults = {};

  let pushTapper = vinylTapper({
    provideBuffer: true,
    terminate: true
  });
  pushTapper.on('tap', (file, buffer) =>
    pushResults[file.relative] = {
      file,
      buffer
    }
  
  );

  let pullTapper = vinylTapper({
    provideBuffer: true,
    terminate: true
  });
  pullTapper.on('tap', (file, buffer) =>
    pullResults[file.relative] = {
      file,
      buffer
    }
  
  );

  let pushExps = null;
  let pullExps = null;
  let readExps = cb =>
    readTree(pushExpDir, pushExpDir, function(err, results) {
      pushExps = results;
      if (err) {
        cb(err);
        return;
      }
      return readTree(pullExpDir, pullExpDir, function(err, results) {
        pullExps = results;
        if (err) {
          cb(err);
          return;
        }
        return cb();
      }
      );
    }
    )
  ;

  let pushOptions = options.push || {};
  let pullOptions = options.pull || {};

  return describe(title, function() {

    let crusher = null;

    before(done =>
      readExps(function(err) {
        if (err) {
          done(err);
          return;
        }

        let streamCount = 2;
        let streamDone = function() {
          if (--streamCount === 0) {
            done();
          }
        };

        let crusherOptions = defaultCrusherOptions;
        if (options.crusher) {
          crusherOptions = _.merge({}, crusherOptions, options.crusher);
        }
        crusher = cacheCrusher(crusherOptions);

        let runPush = function() {
          let pushWell = vinylFs.src('**/*.*', {
            cwd: pushSrcDir,
            buffer: pushOptions.useBuffer
          }
          );
          return pushWell
            .pipe(crusher.pusher())
            .pipe(pushTapper)
            .on('end', streamDone);
        };

        let runPull = function() {
          let pullWell = vinylFs.src('**/*.*', {
            cwd: pullSrcDir,
            buffer: pullOptions.useBuffer
          }
          );
          return pullWell
            .pipe(crusher.puller())
            .pipe(pullTapper)
            .on('end', streamDone);
        };

        setTimeout(runPush, pushOptions.delay);
        return setTimeout(runPull, pullOptions.delay);
      })
    );


    it('should write the expected push files', () => compareResultsExps(pushResults, pushExps)
    );

    return it('should write the expected pull files', () => compareResultsExps(pullResults, pullExps)
    );
  }
  );
};


describe('cache-crusher', function() {

  makeTests('Simple postfix', {
    srcDir: 'simple-src',
    expDir: 'simple-exp-postfix'
  }
  );

  makeTests('Simple postfix with pull buffer', {
    srcDir: 'simple-src',
    expDir: 'simple-exp-postfix',
    pull: {
      useBuffer: true
    }
  }
  );

  makeTests('Simple postfix with push buffer', {
    srcDir: 'simple-src',
    expDir: 'simple-exp-postfix',
    push: {
      useBuffer: true
    }
  }
  );

  makeTests('Simple postfix with push delay', {
    srcDir: 'simple-src',
    expDir: 'simple-exp-postfix',
    push: {
      delay: 500
    }
  }
  );

  makeTests('Simple postfix with pull delay', {
    srcDir: 'simple-src',
    expDir: 'simple-exp-postfix',
    pull: {
      delay: 500
    }
  }
  );

  return makeTests('Simple append', {
    srcDir: 'simple-src',
    expDir: 'simple-exp-append',
    crusher: {
      hasher: {
        rename: false,
        append: 'rev'
      }
    }
  }
  );
}
);



