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

The following `gulpfile.js` effectively just copies the `src`-tree into `dist` and runs an express-server that statically serves the contents of `dist/client` under the **url** `/static`.

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

The only thing we must configure (but there is much more we *may*) is some mapping between **urls** and so called **tags** (These are path-like strings; by the default, they are generated as the vinyl-file's `path` relative to `crusher.cwd`, which in turn defaults to `process.cwd()`) by specifying the option `mapper.counterparts`.

---

A more complete development-setup that uses `cache-crusher` may be be created with this [yeoman](http://yeoman.io) generator:
[browserify-versatile](https://www.npmjs.com/package/generator-browserify-versatile).

## Architecture

![Architecture diagram](https://rawgit.com/tapirdata/cache-crusher/master/doc/architecture.svg)

A **crusher** object creates **pusher** and **puller** objects by means of its methods `crusher.pusher` and `crusher.puller`.

#### The puller side

A **puller** is a vinyl transform stream to pass your referrer files through. For each file it uses a **extractorCatalog** to find an appropriate **extractor**-class by the file extension. E.g. for an HTML-File this will be `HtmlExtractor`. This class is used to create an **extractor** by applying `crusher.urlBase`.

The **extractor** will provide a search pattern (a `RegExp`) that is used to create a [stream-replacer](https://www.npmjs.com/package/stream-replacer). Each time the **extractor** encounters an **url** (which my refer a resource) it uses the **mapper** to convert that **url** to a **tag**. (A **tag** is an abstraction of a path inside some file-system.)

The **mapper** may reject that conversion request if that very **url** doesn't a refer resource to be crushed. In this case the **extractor** will just leave the **url** unmodified. If the conversion succeeds, the resulting **tag** will be to presented to the **resolver**'s pull interface.

If the **resolver** receives a pull request, it may be either able to return the renamed **tag** immediately (if the corresponding push has occurred already). Otherwise that pull request will be queued until it can be resolved. When that renamed **tag** is available, it will be mapped back to an **url**, which is passed back to the **extractor** that will do the replacement of the referrer file's contents.

#### The pusher side

A **pusher** is a vinyl transform stream to pass your resource files through. For each file, a **tagger** is used to create its original **tag**. This **tag** is passed to the **mapper** to check if it could be converted to an **url** (Thus the **mapper** can be used to exclude files from being renamed). If this check passes, the file is piped through a **hasher** (provided by [stream-hasher](https://www.npmjs.com/package/stream-hasher)), which generates some hash-digest of this file's contents and (optionally) renames this file using that digest. A **tagger** is used to create a second **tag** after renaming. That **tag** pair is feed into the **resolver**'s push interface, where this mapping is stored and may be used to resolve pending pull requests.

Optionally the **pusher** can be configured to not rename the resource file, but just emit the created digest together with the original **tag** and let the **resolver** append that digest as some query string.

## API

#### var crusher = cacheCrusher(options);

Creates a new crusher. Recognized options are:

- `enabled` (boolean, default: `true`): Enable the whole **crusher**. If this is `false`, `puller()` and `pusher()` will create simple pass-through-streams. You can use this to disable **crusher** for development builds. You can use `cruser.setEnabled` to change this setting afterwards.
- `debug` (boolean or `console.log`-like function): Log some useful stuff to this functions, if `true`, use `console.error`.
- `cwd` (a path-string, default: `process.cwd()`): This is used by the default **tagger**, that generates the **tag** as the file's path relative to `crusher.cwd`
- `getExtractor` (`function(file)`): use your extractor factory instead of `crusher.prototype.getExtractor`.
- `getTagger` (`function(options)`): use your tagger factory instead of `crusher.prototype.getTagger`.
- `extractor` (object, default: `{urlBase: '/static/'}`): the options to create the **extractor**.
- `mapper` (object): the options to create the **mapper**. Specify `mapper._` to use your own **mapper** (see `mapper.Mapper` for required interface).
- `resolver` (object, default: `{timeout: 10000}`): the options to create the **resolver**. Specify `resolver._` to use your own **replacer** (see `resolver.Resolver` for required interface).
- `hasher` (object, default: `{rename: 'postfix', digestLength: 8}`): the options to create the **hasher**.

##### extractor options
  - `catalog`
  - `urlBase`

##### mapper options

  - `counterparts`: an array of objects that define a relationship between **urls** and **tags**. Each of these may have these properties:
    - `urlRoot` (string):
    - `tagRoot` (string):
    - `globs` (string or array of strings):, converted to [minimatch](https://www.npmjs.com/package/minimatch)-objects to provide filtering.
    - `globOptions` (object): the options for minimatch creation
    - `hasherOptions` (object): overwrite

    To map an **url** to a **tag**, the **mapper** tries its counterparts in turn untill it finds a hit by this rule:
    - If the **url** starts with `urlRoot`, `rel` will be the remaining tail of the **url**.
    - If `globs` is provided, `rel` is tested against these pattern(s). If it fits:
    - The **tag** is created by appending `rel` to `tagRoot`.

    To map a **tag** to an **url**, the **mapper** tries its counterparts in turn untill it finds a hit by this rule:
    - If the **tag** starts with `tagRoot`, `rel` will be the remaining tail of the **tag**.
    - If `globs` is provided, `rel` is tested against these pattern(s). If it fits:
    - The **url** is created by appending `rel` to `urlRoot`.

    For example, a **mapper** with these counterparts:

    ```js
        [ { urlRoot: '/static',
            tagRoot: 'src/client/scripts',
            globs: ['*.js'],
            globOptions: {matchBase: true}
          },
          { urlRoot: '/static',
            tagRoot: 'src/assets'
            globs: '!images/favicon.ico'
          }
        ]
    ```
      - would map the **url** `'/static/foo/bar.js'` to the **tag** `'src/client/scripts/foo/bar.js'`.
      - would map the **url** `'/static/foo/bar.jpg'` to the **tag** `'src/assets/foo/bar.jpg'`.
      - would not map the **url** `'/static/images/favicon.ico'`, since it is excluded by `globs`.


##### resolver options

  - `timeout` (number): pull-timeout in ms. If this is set, a `TimeoutError` will be thrown, when a pull-request has not been resolved for this duration.

##### hasher options

  These options are just passed to [stream-hasher](https://www.npmjs.com/package/stream-hasher):
  - `algorithm`
  - `digestEncoding`
  - `digestLength`
  - `rename`

  Further there is:
  - `append` (`true`, string or function. Only applicable if `rename === false`): Instead of renaming the resource, the **url** will be modified by appending some query-string constructed by '*digest*:
    - `true`: "?*digest*"
    - string *name*: "?*name*=*digest*"
    - `function` *fn*`: "?" + *fn*(*digest*)


#### crusher.puller(options)

Create a new pull-stream (to pass referer files through).

#### crusher.pusher(options)

Create a new push-stream (to pass resource files through).

…to be continued.

