REPLView = require './slima-repl-view'
StatusView = require './slima-status-view'
ProfileView = require './slima-profiler-view'
SlimeAutocompleteProvider = require './slime-autocomplete'

module.exports =
class SlimaView
  constructor: (serializedState, @swank) ->
    # Start a status view
    @statusView = new StatusView()
    @profileView = new ProfileView(@swank, @)
    # Close any currently-opened REPL's that are leftover in the editor from last time
    process.nextTick =>
      @closeAllREPLs()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @statusView?.destroy()
    @destroyRepl()


  destroyRepl: ->
    @repl?.destroy()
    if @profileView.enabled
      @profileView.toggle()

  showRepl: ->
      # Start a REPL
      @repl = new REPLView(@swank)
      @repl.attach()
      SlimeAutocompleteProvider.setup @swank, @repl

  getElement: ->
    @element

  setStatusBar: (@statusBar) ->
    @statusView.attach(@statusBar)
    @profileView.attach(@statusBar)

  closeAllREPLs: ->
    editors = atom.workspace.getTextEditors()
    for editor in editors
      if editor.getTitle() == 'repl.lisp-repl'
        editor.destroy()
