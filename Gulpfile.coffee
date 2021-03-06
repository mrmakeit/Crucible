gulp = require 'gulp'
mocha = require 'gulp-mocha'
istanbul = require 'gulp-coffee-istanbul'
coveralls = require 'gulp-coveralls'
coffeelint = require 'gulp-coffeelint'
coffee = require 'gulp-coffee'

gulp.task 'default', ->
	require './node_modules/nw/bin/nw'
	return

gulp.task 'test', (done) ->
	gulp.src 'libs/*.coffee'
		.pipe istanbul
			includeUntested: true
		.pipe istanbul.hookRequire()
		.on 'finish', ->
			if process.env.CI
				reporter = 'spec'
			else
				reporter = 'nyan'
			gulp.src 'tests/*.coffee'
				.pipe mocha
					reporter:reporter
				.pipe istanbul.writeReports()
				.on 'end', () ->
					if process.env.CI
						gulp.src 'coverage/**/lcov.info'
							.pipe coveralls()
							.on 'finish', done
					else
						done()
	return null

gulp.task 'lint', ->
	gulp.src ['**/*.coffee','!node_modules/**/*']
		.pipe coffeelint 'coffeelint.json'
		.pipe coffeelint.reporter()
		.pipe coffeelint.reporter 'fail'
