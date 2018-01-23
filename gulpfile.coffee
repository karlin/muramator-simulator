gulp = require("gulp")
gutil = require("gulp-util")
sourcemaps = require("gulp-sourcemaps")
concat = require("gulp-concat")
coffee = require("gulp-coffee")
watch = require('gulp-watch');
plumber = require("gulp-plumber")
connect = require("gulp-connect")
del = require('del')
open = require("open")
http = require("http")

gulp.task 'clean', ->
  del './build'

gulp.task "copy", ->
  gulp.src([
    "./src/*.json"
    "./src/*.html"
    "./src/*.css"
  ]).pipe(gulp.dest("build"))

gulp.task "coffee", ->
  gulp.src(["./src/**/*.coffee"])
  .pipe(plumber())
  .pipe(sourcemaps.init())
  .pipe(coffee())
  .pipe(sourcemaps.write())
  .pipe(gulp.dest("./build/js"))

gulp.task "default", [
  "coffee"
  "copy"
], ->
  gulp.src([
    "./lib/**/*.js"
    # "./build/js/**.js"
  ])
  # .pipe(concat("all.js", {prefix: 2}))
  .pipe(gulp.dest("./build/"))
  .pipe(connect.reload())

gulp.task 'html', ->
  gulp.src('./build/*.html')
    .pipe(connect.reload())

gulp.task 'watch:src', ->
  gulp.watch [
    './src/**/*.coffee'
    './src/**/*.html'
    './src/**/*.css'
  ], ['default']

gulp.task 'serve', ['default'], ->
  connect.server
    livereload: true

gulp.task 'watch', ['serve', 'watch:src']
