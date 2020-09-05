REPLView = require './slima-repl-view'
StatusView = require './slima-status-view'
ProfileView = require './slima-profiler-view'
SlimeAutocompleteProvider = require './slime-autocomplete'

module.exports =
class SlimaView
  constructor: (serializedState, @Slima) ->
    # Start a status view
    @statusView = new StatusView()
    @profileView = new ProfileView(@Slima.swank, @)
    # Close any currently-opened REPL's that are leftover in the editor from last time
    process.nextTick =>
      @closeAllREPLs()

  # Returns an object that can be retrieved when package is activated
  serialize: -> undefined

  # Tear down any state and detach
  destroy: ->
    @statusView?.destroy()
    @destroyRepl()


  destroyRepl: ->
    if @repl
      @repl.editor.moveToBottom()
      @repl.editor.moveToEndOfLine()
      @repl.appendText('\n\n;;;; Lisp instance killed\n', false)
      @repl.destroy()
    if @profileView.enabled
      @profileView.toggle()

  showRepl: ->
    if @repl and @repl.notDestroyed
      # Reconfigure existing repl
      @repl.setupRepl()
    else
      # Start a new REPL
      @repl = new REPLView(@Slima, @Slima.swank)
      @repl.attach()
      SlimeAutocompleteProvider.setup @Slima.swank, @repl

  getElement: ->
    @element

  setStatusBar: (@statusBar) ->
    try
      @statusView.attach(@statusBar)
      @profileView.attach(@statusBar)
    catch error
      atom.notifications.addError("Failed to attach to the status bar. Please restart Atom",
            description:"SLIMA sometimes has issues connecting to the status bar. If restart Atom doesn't fix this message, please [report the issue](https://github.com/neil-lindquist/SLIMA/issues)",
            dismissable:true)

  closeAllREPLs: ->
    editors = atom.workspace.getTextEditors()
    for editor in editors
      if editor.getTitle() == 'repl.lisp-repl'
        editor.destroy()
