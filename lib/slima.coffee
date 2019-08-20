{CompositeDisposable, Point, Range} = require 'atom'
Swank = require 'swank-client'
SlimaView = require './slima-view'
paredit = require 'paredit.js'
slime = require './slime-functions'
SlimaEditor = require './slima-editor'
SlimeAutocompleteProvider = require './slime-autocomplete'
SwankStarter = require './swank-starter'

module.exports = Slima =
  views: null
  subs: null
  asts: {}
  pkgs: {}
  process: null

  # Provide configuration options
  config:
    slimePath:
      title: 'Slime Path'
      description: 'Path to where SLIME resides on your computer.'
      type: 'string'
      default: '~/Desktop/slime'
      order: 3

    lispName:
      title: 'Lisp Process'
      description: 'Name of Lisp to run'
      type: 'string'
      default: 'sbcl'
      order: 2

    autoStart:
      title: 'Start lisp when Atom opens'
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
          title: 'Show the swank messages in the JavaScript console'
          description: 'When enabled, every message coming from the swank server will be shown in the JavaScript console.'
          type: 'boolean'
          default: false
        connectionAttempts:
          title: 'Number of connection attempts to make with the swank server (0.2s per attempt)'
          description: 'If Lisp takes a while to load, then increasing the number of attempts may help (for advanced users using docker)'
          type: 'integer'
          default: 5
        swankCommand:
          title: 'Custom Swank Command'
          description: 'If not blank, used to start the swank server instead of the fields above'
          type: 'string'
          default: ''
        swankHostname:
          title: 'Swank Hostname'
          description: 'The hostname of the swank server to connect to'
          type: 'string'
          default: 'localhost'
        swankPort:
          title: 'Swank Port'
          description: 'The port used by the swank server to connect to'
          type: 'integer'
          default: 4005



  activate: (state) ->
    # Setup a swank client instance
    @setupSwank()
    @views = new SlimaView(state.viewsState, @swank)
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subs = new CompositeDisposable
    @ases = new CompositeDisposable

    # Setup connections
    @subs.add atom.commands.add 'atom-workspace', 'slime:start': => @swankStart()
    @subs.add atom.commands.add 'atom-workspace', 'slime:connect': => @swankConnect()
    @subs.add atom.commands.add 'atom-workspace', 'slime:disconnect': => @swankDisconnect()
    @subs.add atom.commands.add 'atom-workspace', 'slime:restart': => @swankRestart()
    @subs.add atom.commands.add 'atom-workspace', 'slime:profile': => @profileStart()

    # Keep track of all Lisp editors
    @subs.add atom.workspace.observeTextEditors (editor) =>
      if editor.getGrammar().name.match /Lisp/i
        ase = new SlimaEditor(editor, @views.statusView, @swank)
        @ases.add ase
      else
        editor.onDidChangeGrammar =>
          if editor.getGrammar().name.match /Lisp/i
            ase = new SlimaEditor(editor, @views.statusView, @swank)
            @ases.add ase

    # If desired, automatically start Swank.
    if atom.config.get('slima.autoStart')
      @swankStart()



  # Sets up a swank client but does not connect
  setupSwank: () ->
    host = atom.config.get 'slima.advancedSettings.swankHostname'
    port = atom.config.get 'slima.advancedSettings.swankPort'
    @swank = new Swank.Client(host, port);
    @swank.on 'disconnect', =>
      @swankCleanup

    atom.config.onDidChange 'slima.advancedSettings.swankHostname', (newHost)=>
      @swank.host = newHost.newValue
    atom.config.onDidChange 'slima.advancedSettings.swankPort', (newPort)=>
      @swank.port = newPort.newValue


  # Start a swank server and then connect to it
  swankStart: () ->
    # Start a new process
    @process = new SwankStarter
    if @process.start()
      @swank.process = @process
      # Try and connect if successful!
      @swankConnect()

  # Connect the to a running swank client
  swankConnect: () ->
    atom.notifications.addInfo('Please wait...')
    @tryToConnect 0


  # Start up the profile view
  profileStart: () ->
    if @swank.connected and @views.repl
      @views.profileView.toggle()
    else
      atom.notifications.addWarning("Cannot profile without the REPL")

  tryToConnect: (i) ->
    if i > atom.config.get 'slima.advancedSettings.connectionAttempts'
      atom.notifications.addWarning("Couldn't connect to Lisp! Did you start a Lisp swank server?\n\nIf this is your first time running `slima`, this is normal. Try running `slime:connect` in a minute or so once it's finished compiling.")
      return false
    promise = @swank.connect()
    promise.then (=> @swankConnected()), ( => setTimeout ( => @tryToConnect(i + 1)), 200)

  swankConnected: () ->
    console.log "Slime Connected!!"
    return @swank.initialize().then =>
      atom.notifications.addSuccess('Connected to Lisp!', detail:'Code away!')
      @views.statusView.message("Slime connected!")
      @views.showRepl()


  swankDisconnect: () ->
    @swank.quit()
    @swankCleanup()

  # releases resources and closes the REPL pane
  swankCleanup: () ->
    atom.notifications.addError("Disconnected from Lisp")
    @views.statusView.message('Slime not connected.')
    @views.destroyRepl()

  swankRestart: () ->
    @swankDisconnect()
    setTimeout(( => @swankStart()), 500)


  deactivate: ->
    @subs.dispose()
    @ases.dispose()
    @views.destroy()
    @process.destroy()

  serialize: ->
    viewsState: @views.serialize()

  consumeStatusBar: (statusBar) ->
    @views.setStatusBar(statusBar)

  provideSlimeAutocomplete: -> SlimeAutocompleteProvider
