{BufferedProcess} = require 'atom'
fs = require 'fs'
path = require 'path'

# Helps to start a Swank server automatically so the
# user doesn't have to start one in a separate terminal
module.exports =
class SwankStarter
  process: null

  start: () ->
    manualCommand = atom.config.get 'slima.advancedSettings.swankCommand'

    options = {cwd: @get_cwd()}
    if manualCommand == ''
      success = @check_path()
      if not success
        atom.notifications.addWarning("Did you set up `slima` as noted in the package's preferences? The \"Slime Path\" directory can't be opened. Please double check it!")
        return false
      command = @lisp
      args = []
      args.push 'run' if command.match(/ros/)
      if not command.match(/clisp|lw/)
        args.push '--load'
      else
        args.push '-load' if command.match(/lw/)
      args.push @swank_script
    else
      command = manualCommand
      options.windowsVerbatimArguments = true
      options.shell = true
      args = []
    @process = new BufferedProcess({
      command: command,
      args: args,
      options: options,
      stdout: @stdout_callback,
      stderr: @stderr_callback,
      exit: @exit_callback
    })
    console.log "Started a swank server"
    return true

  check_path: () ->
    # Retrieve the slime path and lisp name
    @lisp = atom.config.get 'slima.lispName'
    @path = atom.config.get 'slima.slimePath'
    if @path[@path.length - 1] == path.sep
      @path = @path[0...-1]
    else
      try
        if fs.statSync(@path).isFile()
          @swank_script = @path
          return true
      catch e
       pass
    @swank_script = "#{@path}#{path.sep}start-swank.lisp"
    # Check if the slime path exists; return true or false
    try
      return fs.statSync(@swank_script).isFile()
    catch e
      console.log e
      return false

  stdout_callback: (output) ->
    if atom.config.get 'slima.advancedSettings.showSwankDebug'
      console.log output

  stderr_callback: (output) ->
    if atom.config.get 'slima.advancedSettings.showSwankDebug'
      console.log output

  get_cwd: ->
    ed = atom.workspace.getActiveTextEditor()?.getPath()
    return atom.project.getPaths()[0] unless ed?
    return path.dirname(ed)

  exit_callback: (code) ->
    console.log "Lisp process exited: #{code}"

  destroy: () ->
    @process?.kill()
