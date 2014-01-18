# # Build Proccess Using Gulp

# Dependencies
gulp = require 'gulp'
gutil = require 'gulp-util'

coffee = require 'gulp-coffee'
coffeelint = require 'gulp-coffeelint'
ngmin = require 'gulp-ngmin'
uglify = require 'gulp-uglify'
concat = require 'gulp-concat'
header = require 'gulp-header'

pkg = require './package.json'

# ## Tasks
banner = """/*!
 * <%= name %>
 *
 * @author [<%= author.name %>](<%= author.url %>)
 * @version <%= version %>
 * @license <%= licenses[0].type %>
 */

"""

gulp.task "compileScripts", ->
  gulp.src("src/**/*.coffee")
  .pipe(coffeelint())
  .pipe(coffeelint.reporter())
  .pipe(coffee().on('error', gutil.log))
  .pipe(ngmin())
  .pipe(concat("model.js"))
  .pipe(header(banner, pkg))
  .pipe(gulp.dest("dist/"))
  .pipe(uglify(output: {comments: /^!|@preserve|@license|@cc_on/i}))
  .pipe(concat("model.min.js"))
  .pipe(gulp.dest("dist/"))

gulp.task "watch", ['compile'], ->
  gulp.watch "src/**/*.coffee", ->
    gulp.run 'compileScripts'

# ## Combined Tasks

gulp.task "compile", ['compileScripts'], ->
