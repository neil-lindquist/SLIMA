{BufferedProcess} = require 'atom'
fs = require 'fs'
path = require 'path'
os = require 'os'
tmp = require 'temporary'

# Helps to start a Swank server automatically so the
# user doesn't have to start one in a separate terminal
module.exports =
class SwankStarter
  process: null
  cwd: null

  start: () ->
    manualCommand = atom.config.get 'slima.advancedSettings.swankCommand'
    @cwd = @get_cwd()
    @lisp = atom.config.get 'slima.lispName'

    options = {cwd: @cwd}
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
    # Retrieve the slime path
    @path = atom.config.get 'slima.slimePath'
    @path = @path.replace /^~(?=[\\/])/, os.homedir()
    if @path[@path.length - 1] == path.sep
      @path = @path[0...-1]
    else
      try
        if fs.statSync(@path).isFile()
          @swank_script = @path
          return true

    loader_path = "#{@path}#{path.sep}swank-loader.lisp"
    @swank_starter = new tmp.File("swank-starter.lisp")
    @swank_script = @swank_starter.path
    @swank_starter.writeFileSync(
        "(load \"#{loader_path.replace(/\\/g, "\\\\").replace(/"/g, "\\\"")}\" :verbose t) " +
        "(funcall (read-from-string \"swank-loader:init\") " +
                 ":from-emacs t) " +
        "(funcall (read-from-string \"swank:create-server\") " +
                 ":port 4005 " +
                 ":dont-close nil)")
    try
      return fs.statSync(loader_path).isFile()
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
    proj = atom.project.getPaths()[0]
    return proj if proj?

    ed = atom.workspace.getActiveTextEditor()?.getPath()
    return path.dirname(ed) if ed?

    return ""

  exit_callback: (code) ->
    @swank_starter?.unlink()
    @swank_starter = null
    console.log "Lisp process exited: #{code}"

  destroy: () ->
    @swank_starter?.unlink()
    @swank_starter = null
    @process?.kill()
