# cache-crusher [![Build Status](https://secure.travis-ci.org/tapirdata/cache-crusher.png?branch=master)](https://travis-ci.org/tapirdata/cache-crusher) [![Dependency Status](https://david-dm.org/tapirdata/cache-crusher.svg)](https://david-dm.org/tapirdata/cache-crusher) [![devDependency Status](https://david-dm.org/tapirdata/cache-crusher/dev-status.svg)](https://david-dm.org/tapirdata/cache-crusher#info=devDependencies)

> A cache-buster for [gulp](http://gulpjs.com), that integrates itself neatly into your tasks.

## Usage

Let's say, you have this simplified directory structure:

```bash
gulpfile.js
src
├── client
│   ├── pages
│   │   └── main.html
│   └── styles
│       └── main.css
└── server
    └── scripts
        └── start.js
```
You may find the whole example project under `examples/simple`.

The following `gulpfile.js` effectively just copies the `src`-tree into `dist` and runs an express-server that statically serves the contents of `dist/client` under the url `/static`.

```javascript
gulp = require('gulp');
cacheCrusher = require('cache-crusher');

crusher = cacheCrusher({
  mapper: {
    counterparts: [{urlRoot: '/static', tagRoot: 'src/client'}]
  }
});

gulp.task('build-client-styles', function() {
  return gulp.src('src/client/styles/*.css')
  .pipe(crusher.pusher())
  .pipe(gulp.dest('dist/client/styles'));
});

gulp.task('build-client-pages', function() {
  return gulp.src('src/client/pages/*.html')
  .pipe(crusher.puller())
  .pipe(gulp.dest('dist/client/pages'));
});

gulp.task('build-server-scripts', function() {
  return gulp.src('src/server/scripts/*.js')
  .pipe(gulp.dest('dist/server/scripts'));
});

gulp.task('build', [
  'build-client-styles',
  'build-client-pages',
  'build-server-scripts']);

gulp.task('run', ['build'], function() {
  require('./dist/server/scripts/start.js');
});

gulp.task('default', ['run']);
```

…indeed, there is a little bit more to see here: As we pipe our resource (`main.css`) through a **pusher**, it will be automatically renamed to `main-<digest>.css`; as we pipe our referrer (`main.html`) through a **puller**, it will be scanned for references that start with the (configurable) `urlBase` `/static` and get that references be replaced by the appropriately renamed ones.

The only thing we must configure (but there is much more we *may*) is some mapping between urls and so called **tags** (These are path-like strings; by the default, they are generated as the vinyl-file's `path` relative to `crusher.cwd`, which in turn defaults to `process.cwd()`) by specifying the option `mapper.counterparts`.

---

A more complete development-setup that uses `cache-crusher` may be be created with this [yeoman](http://yeoman.io) generator: 
[browserify-versatile](https://www.npmjs.com/package/generator-browserify-versatile).

## Architecture

![Architecture diagram](https://rawgit.com/tapirdata/cache-crusher/master/doc/architecture.svg)

A **crusher** object creates **pusher** and **puller** objects by means of its methods `crusher.pusher` and `crusher.puller`.

#### The puller side 

A **puller** is a vinyl transform stream to pass your referrer files through. For each file it uses a **extractorCatalog** to find an appropriate **extractor**-class by the file extension. E.g. for an Html-File this will be `HtmlExtractor`. This class is used to create an **extractor** by applying `crusher.urlBase`.

The **extractor** will provide a search pattern (a `RegExp`) that is used to create a [stream-replacer](https://www.npmjs.com/package/stream-replacer). Each time the **extractor** encounters an **url** (which my refer a resource) it uses the **mapper** to convert that ***url** to a **tag**. (A **tag** is an abstraction of a path inside some file-system.)

The **mapper** may reject that conversion request if that very **url** doesn't a refer resource to be crushed. In this case the **extractor** will just leave the **url** unmodified. If the conversion succeeds, the resulting **tag** will be to presented to the **resolver**'s pull interface. 

If the **resolver** receives a pull request, it may be either able to return the renamed **tag** immediately (if the corresponding push has occured already). Otherwise that pull request will be queued until it can be resolved. When that renamed **tag** is available, it will be mapped back to an **url**, which is passed back to the **extractor** that will do the replacement of the referrer file's contents. 

#### The pusher side 

A **pusher** is a vinyl transform stream to pass your resource files through. Each file is piped through a [stream-hasher](https://www.npmjs.com/package/stream-hasher), which generates some hash-digest of this file's contents and (optionally) renames this file using that digest. A **tagger** is used to create a **tag** of this resource before and after renaming. That **tag** pair is feed into the **resolver**'s push interface, where this mapping is stored and may be used to resolve pending pull requests.

Optionally the **pusher** can be configures to not rename the resource file, but just emit the created digest together with the original **tag** and let the **resolver** append that digest as some query string. 

## Options

…will be documented soon.

