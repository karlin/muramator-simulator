gulp = require("gulp")
gutil = require("gulp-util")
concat = require("gulp-concat-sourcemap")
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
    "./src/*.js"
  ]).pipe gulp.dest("build")

gulp.task "coffee", ->
  gulp.src(["./src/**/*.coffee"])
  .pipe(plumber())
  .pipe(coffee())
  .pipe gulp.dest("./src")

gulp.task "default", [
  "coffee"
  "copy"
], ->
  gulp.src([
    "./lib/**/*.js"
    "./src/svg.js"
    "./src/muramator.js"
  ])
  .pipe(concat("all.js"), {prefix: 1})
  .pipe gulp.dest("./build/")

# gulp.task "watch", ->
#   gulp.watch "./src/**/*.html", ["default"]
#   gulp.watch "./src/**/*.js", ["default"]
#   gulp.watch "./lib/**/*.js", ["default"]
#   gulp.watch "./src/**/*.coffee", ["coffee"]

gulp.task "server", ["watch"], (callback) ->
  # devApp = undefined
  # devServer = undefined
  # devAddress = undefined
  # devHost = undefined
  # url = undefined
  log = gutil.log
  colors = gutil.colors
  devApp = connect().server

  # change port and hostname to something static if you prefer
  devServer = http.createServer(devApp).listen(0) #, hostname
  devServer.on "error", (error) ->
    log colors.underline(colors.red("ERROR")) + " Unable to start server!"
    callback error

  devServer.on "listening", ->
    devAddress = devServer.address()
    console.log(devAddress)
    devHost = (if devAddress.address is "::" then "localhost" else devAddress.address)
    url = "http://" + devHost + ":" + devAddress.port + "/muramator.html"
    log ""
    log "Started dev server at " + colors.magenta(url)
    if gutil.env.open
      log "Opening dev server URL in browser"
      open url
    else
      log colors.gray("(Run with --open to automatically open URL on startup)")
    log ""
    callback()
    return

  return


gulp.task 'html', ->
  gulp.src('./src/*.html', './*.js')
    .pipe(connect.reload())
 
gulp.task 'watch', ->
  gulp.watch(['./src/*.html'], ['html'])

gulp.task 'serve', ['default'], ->
  connect.server
    root: 'build'
    livereload: true