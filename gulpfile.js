// Muramator - created with Gulp Fiction
var gulp     = require("gulp"),
    gutil    = require("gulp-util"),
    concat   = require('gulp-concat-sourcemap'),
    coffee   = require("gulp-coffee"),
    open     = require("open"),
    connect  = require("connect"),
    plumber  = require('gulp-plumber'),
    http     = require('http');

gulp.task('copy', function(){
  gulp.src(['./src/*.html','./src/*.css'])
    .pipe(gulp.dest('build'));
});

gulp.task("coffee", function () {
  gulp.src(["./src/**/*.coffee"])
    .pipe(plumber())
    .pipe(coffee())
    .pipe(gulp.dest("./src"));
});

gulp.task("default", ['coffee', 'copy'], function () {
  gulp.src(["./lib/**/*.js", "./src/**/*.js"])
    .pipe(concat("all.js"))
    .pipe(gulp.dest("./build/"));
});

gulp.task("watch", function () {
    gulp.watch("./src/**/*.html", ["default"]);
    gulp.watch("./src/**/*.js", ["default"]);
    gulp.watch("./lib/**/*.js", ["default"]);
    gulp.watch("./src/**/*.coffee", ["coffee"]);
});

gulp.task('server', ['watch'], function(callback) {
  var devApp, devServer, devAddress, devHost, url, log=gutil.log, colors=gutil.colors;

  devApp = connect()
    .use(connect.logger('dev'))
    .use(connect.static('build'));

  // change port and hostname to something static if you prefer
  devServer = http.createServer(devApp).listen(0 /*, hostname*/);

  devServer.on('error', function(error) {
    log(colors.underline(colors.red('ERROR'))+' Unable to start server!');
    callback(error); // we couldn't start the server, so report it and quit gulp
  });

  devServer.on('listening', function() {
      devAddress = devServer.address();
      devHost = devAddress.address === '0.0.0.0' ? 'localhost' : devAddress.address;
      url = 'http://' + devHost + ':' + devAddress.port + '/muramator.html';

      log('');
      log('Started dev server at '+colors.magenta(url));
      if(gutil.env.open) {
          log('Opening dev server URL in browser');
          open(url);
      } else {
          log(colors.gray('(Run with --open to automatically open URL on startup)'));
      }
      log('');
      callback();
  });
});
