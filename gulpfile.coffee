gulp = require("gulp")
gutil = require("gulp-util")
concat = require("gulp-concat-sourcemap")
coffee = require("gulp-coffee")
open = require("open")
connect = require("connect")
plumber = require("gulp-plumber")
http = require("http")

gulp.task "copy", ->
  gulp.src([
    "./src/*.json"
    "./src/*.html"
    "./src/*.css"
    "./src/*.js"
  ]).pipe gulp.dest("build")

gulp.task "coffee", ->
  gulp.src(["./src/**/*.coffee"]).pipe(plumber()).pipe(coffee()).pipe gulp.dest("./src")

gulp.task "default", [
  "coffee"
  "copy"
], ->
  gulp.src([
    "./lib/**/*.js"
    "./src/**/*.js"
  ]).pipe(concat("all.js")).pipe gulp.dest("./build/")

gulp.task "watch", ->
  gulp.watch "./src/**/*.html", ["default"]
  gulp.watch "./src/**/*.js", ["default"]
  gulp.watch "./lib/**/*.js", ["default"]
  gulp.watch "./src/**/*.coffee", ["coffee"]

gulp.task "server", ["watch"], (callback) ->
  # devApp = undefined
  # devServer = undefined
  # devAddress = undefined
  # devHost = undefined
  # url = undefined
  log = gutil.log
  colors = gutil.colors
  devApp = connect()
    .use connect.logger("dev")
    .use connect.static("build")

  # change port and hostname to something static if you prefer
  devServer = http.createServer(devApp).listen(0) #, hostname
  devServer.on "error", (error) ->
    log colors.underline(colors.red("ERROR")) + " Unable to start server!"
    callback error

  devServer.on "listening", ->
    devAddress = devServer.address()
    devHost = (if devAddress.address is "0.0.0.0" then "localhost" else devAddress.address)
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
