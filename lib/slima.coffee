{CompositeDisposable, Point, Range} = require 'atom'
Swank = require 'swank-client'
SlimaView = require './slima-view'
paredit = require 'paredit.js'
slime = require './slime-functions'
SlimaEditor = require './slima-editor'
SlimeAutocompleteProvider = require './slime-autocomplete'
SwankStarter = require './swank-starter'
utils = require './utils'

module.exports = Slima =
  views: null
  subs: null
  asts: {}
  pkgs: {}
  process: null

  # Provide configuration options
  config:
    slimePath:
      title: 'SLIME Path'
      description: 'Path to where SLIME resides on your computer.'
      type: 'string'
      default: '~/Desktop/slime'
      order: 3

    lispName:
      title: 'Lisp Process'
      description: 'Name of Lisp executable to run.  This cannot include any command line arguments'
      type: 'string'
      default: 'sbcl'
      order: 2

    autoStart:
      title: 'Start Lisp when Atom opens'
      description: 'When checked, a Lisp REPL will automatically open every time you open atom.'
      type: 'boolean'
      default: false
      order: 1

    advancedSettings:
      title: 'Advanced Settings'
      type: 'object'
      order: 4
      properties:
        showSwankDebug:
          title: 'Show the Swank messages in the JavaScript console'
          description: 'When enabled, every message coming from the Swank server will be shown in the JavaScript console.'
          type: 'boolean'
          default: false
        connectionAttempts:
          title: 'Number of connection attempts to make with the swank server (0.2s per attempt)'
          description: 'If Lisp takes a while to load, then increasing the number of attempts may help (for advanced users using docker)'
          type: 'integer'
          default: 5
        swankCommand:
          title: 'Custom Swank Command'
          description: 'If not blank, used to start the swank server instead of the fields above.  See [the SLIMA wiki](https://github.com/neil-lindquist/SLIMA/wiki) for more information.'
          type: 'string'
          default: ''
        swankHostname:
          title: 'Swank Hostname'
          description: 'The hostname of the Swank server to connect to'
          type: 'string'
          default: 'localhost'
        swankPort:
          title: 'Swank Port'
          description: 'The port used by the Swank server to connect to'
          type: 'integer'
          default: 4005



  activate: (state) ->
    # Setup a swank client instance
    Slima.setupSwank()
    Slima.views = new SlimaView(state.viewsState, Slima)
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    Slima.subs = new CompositeDisposable
    Slima.slimaEditors = []

    # Setup connections
    Slima.subs.add atom.commands.add 'atom-workspace', 'slime:start': => @swankStart()
    Slima.subs.add atom.commands.add 'atom-workspace', 'slime:quit': => @swankQuit()
    Slima.subs.add atom.commands.add 'atom-workspace', 'slime:connect': => @swankConnect()
    Slima.subs.add atom.commands.add 'atom-workspace', 'slime:disconnect': => @swankDisconnect()
    Slima.subs.add atom.commands.add 'atom-workspace', 'slime:restart': => @swankRestart()
    Slima.subs.add atom.commands.add 'atom-workspace', 'slime:profile': => @profileStart()

    # Keep track of all Lisp editors
    Slima.subs.add atom.workspace.observeTextEditors (editor) =>
      if editor.getGrammar().name.match /Lisp/i
        slimaEditor = new SlimaEditor(Slima, editor, @views.statusView, @swank)
        Slima.slimaEditors.push slimaEditor
      else
        editor.onDidChangeGrammar =>
          if editor.getGrammar().name.match /Lisp/i
            slimaEditor = new SlimaEditor(Slima, editor, @views.statusView, @swank)
            Slima.slimaEditors.push slimaEditor
          else
            index = Slima.slimaEditors.findIndex((se) -> se.editor == editor)
            if index != -1
              Slima.slimaEditors[index].dispose()
              Slima.slimaEditors.splice(index, 1)

    # If desired, automatically start Swank.
    if atom.config.get('slima.autoStart')
      Slima.swankStart()


  setupLinter: (registerIndie) ->
    Slima.linter = registerIndie(
      name: 'SLIMA'
    )
    Slima.subs.add(Slima.linter)


  # Sets up a swank client but does not connect
  setupSwank: () ->
    host = atom.config.get 'slima.advancedSettings.swankHostname'
    port = atom.config.get 'slima.advancedSettings.swankPort'
    Slima.swank = new Swank.Client(host, port)
    Slima.swank.on 'disconnect', Slima.swankCleanup
    Slima.swank.on 'compiler_notes', Slima.processCompilerNotes

    atom.config.onDidChange 'slima.advancedSettings.swankHostname', (newHost) ->
      Slima.swank.host = newHost.newValue
    atom.config.onDidChange 'slima.advancedSettings.swankPort', (newPort) ->
      Slima.swank.port = newPort.newValue


  # Start a swank server and then connect to it
  swankStart: () ->
    # If we've already launched a swank server
    if Slima.process
      console.log Slima.process
      # If that process is still alive
      if Slima.process.process
        atom.notifications.addWarning('Swank server already running.  Do you mean `slime:restart`?')
      else
        Slima.swankRestart()
    else
      # Start a new process
      Slima.process = new SwankStarter
      if Slima.process.start()
        Slima.swank.process = Slima.process
        # Try and connect if successful!
        Slima.swankConnect()

  # Connect the to a running swank client
  swankConnect: () ->
    atom.notifications.addInfo('Please wait...')
    Slima.tryToConnect 0

  swankDisconnect: () ->
    if Slima.process
      atom.notifications.addWarning('Cannot disconnect from a Swank server spawned by SLIMA.  Do you mean `slime:quit`?')
    else
      Slima.swank.disconnect()

  swankDisconnectOrQuit: () ->
    if Slima.process
      Slima.swankQuit()
    else
      Slima.swank.disconnect()

  # Start up the profile view
  profileStart: () ->
    if Slima.swank.connected and Slima.views.repl
      Slima.views.profileView.toggle()
    else
      atom.notifications.addWarning("Cannot profile without the REPL")

  tryToConnect: (i) ->
    if i > atom.config.get 'slima.advancedSettings.connectionAttempts'
      atom.notifications.addWarning("Couldn't connect to Lisp! Did you start a Lisp swank server?\n\nIf this is your first time running `slima`, this is normal. Try running `slime:connect` in a minute or so once it's finished compiling.")
      return false
    promise = Slima.swank.connect()
    promise.then Slima.swankConnected, ( -> setTimeout ( -> Slima.tryToConnect(i + 1)), 200)

  swankConnected: () ->
    console.log "Slime Connected!!"
    return Slima.swank.initialize().then ->
      atom.notifications.addSuccess('Connected to Lisp!', detail:'Code away!')
      Slima.views.statusView.message("SLIMA connected!")
      Slima.views.showRepl()


  swankQuit: () ->
    Slima.swank.quit()
    Slima.swankCleanup()

  # releases resources and closes the REPL pane
  swankCleanup: () ->
    atom.notifications.addError("Disconnected from Lisp")
    Slima.views.statusView.message('Slime not connected.')
    Slima.views.destroyRepl()
    Slima.process = null

  swankRestart: () ->
    if Slima.process
      Slima.swankQuit()
      setTimeout(( -> Slima.swankStart()), 500)
    else
      atom.notifications.addWarning('Only Swank servers created by SLIMA can be restarted')


  deactivate: ->
    Slima.subs.dispose()
    Slima.slimaEditors.forEach((slimaEditor) -> slimaEditor.dispose())
    Slima.views.destroy()
    if Slima.process
      Slima.process.destroy()
      Slima.process = null

  serialize: ->
    viewsState: Slima.views.serialize()

  consumeStatusBar: (statusBar) ->
    Slima.views.setStatusBar(statusBar)

  provideSlimeAutocomplete: -> SlimeAutocompleteProvider


  processCompilerNotes: (notes) ->
    if Slima.linter
      linter_messages = []
      try
        for note in notes
          message = {}
          {source_file, source_editor, point} = utils.getSourceLocation(note.location)
          if source_editor? and note.severity != 'read-error'
            ast = paredit.parse(source_editor.getText())
            start_idx = utils.convertPointToIndex(point, source_editor)
            end_idx = paredit.navigator.forwardSexp(ast, start_idx)
            position_end = utils.convertIndexToPoint(end_idx, source_editor)

            if position_end.row != point.row
              position_end = source_editor.getBuffer().rangeForRow(point.row).end
          else
            position_end = [point.line, point.col+1]

          message.location = {file: source_file, position: [point, position_end]}
          message.excerpt = note.message
          switch note.severity
            when "note", "redefinition"
              message.severity = "info"
            when "style-warning", "warning", "early-deprecation-warning", "late-deprecation-warning", "final-deprecation-warning"
              message.severity = "warning"
            else # read-error, error
              message.severity = "error"
          linter_messages.push(message)
      catch error
        console.warn error
        atom.notifications.addWarning('Error processing compiler notes', {detail: error.message})

      Slima.linter.setAllMessages(linter_messages)
