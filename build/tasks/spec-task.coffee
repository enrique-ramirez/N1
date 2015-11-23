fs = require 'fs'
path = require 'path'
request = require 'request'
proc = require 'child_process'

executeTests = (test, grunt, done) ->
  testSucceeded = false
  testOutput = ""

  testProc = proc.spawn(test.cmd, test.args, {stdio: "inherit"})

  # testProc.stdout.on 'data', (data) ->
  #   str = data.toString()
  #   testOutput += str
  #   console.log(str)
  #   if str.indexOf(' 0 failures') isnt -1
  #     testSucceeded = true
  #
  # testProc.stderr.on 'data', (data) ->
  #   str = data.toString()
  #   testOutput += str
  #   grunt.log.error(str)

  testProc.on 'error', (err) ->
    grunt.log.error("Process error: #{err}")

  testProc.on 'close', (exitCode, signal) ->
    if testSucceeded and exitCode is 0
      done()
    else
      testOutput = testOutput.replace(/\x1b\[[^m]+m/g, '')
      url = "https://hooks.slack.com/services/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"
      request.post
        url: url
        json:
          username: "Edgehill Builds"
          text: "Aghhh somebody broke the build. ```#{testOutput}```"
      , (err, httpResponse, body) ->
        done(false)

module.exports = (grunt) ->

  grunt.registerTask 'run-spectron-specs', 'Run spectron specs', ->
    electronLauncher = path.resolve("./electron/Electron.app/Contents/MacOS/Electron")
    nylasRoot = path.resolve('.')
    electronArgs = [nylasRoot]
    buildDir = grunt.config.get('nylasGruntConfig.buildDir')
    nylasArgs = ["--test=window", "--enable-logging", "--resource-path=#{nylasRoot}"]

    done = @async()
    npm = path.resolve "./build/node_modules/.bin/npm"
    grunt.log.writeln 'App exists: ' + fs.existsSync(electronLauncher)

    process.chdir('./spectron')
    grunt.log.writeln "Current dir: #{process.cwd()}"
    installProc = proc.exec "#{npm} install", (error) ->
      if error?
        process.chdir('..')
        grunt.log.error('Failed while running npm install in spectron folder')
        grunt.fail.warn(error)
        done(false)
      else
        npmArgs = [
          'test'
          "ELECTRON_LAUNCHER=#{electronLauncher}"
          "ELECTRON_ARGS=#{electronArgs.join(',')}"
          "NYLAS_ARGS=#{nylasArgs.join(',')}"
        ]
        executeTests cmd: npm, args: npmArgs, grunt, (succeeded) ->
          process.chdir('..')
          done(succeeded)

  grunt.registerTask 'run-edgehill-specs', 'Run the specs', ->
    done = @async()
    executeTests cmd: './N1.sh', args: ['--test'], grunt, done
