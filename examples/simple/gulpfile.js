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

gulp.task('build', ['build-client-styles', 'build-client-pages', 'build-server-scripts']);

gulp.task('run', ['build'], function() {
  require('./dist/server/scripts/start.js');
});

gulp.task('default', ['run']);

