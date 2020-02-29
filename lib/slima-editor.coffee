{CompositeDisposable, Point, Range} = require 'atom'
minibuffer = require './minibuffer'
paredit = require 'paredit.js'
slime = require './slime-functions'
Bubble = require './slima-bubble'
utils = require './utils'

module.exports =
class SlimaEditor
  subs: null
  ast: null
  pkg: null
  mouseMoveTimeout: null

  constructor: (@editor, @statusView, @swank) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @editorElement = atom.views.getView(@editor)
    @subs = new CompositeDisposable
    @subs.add @editor.onDidStopChanging => @stoppedEditingCallback()
    @subs.add @editor.onDidChangeCursorPosition => @cursorMovedCallback()
    @subs.add @editor.onDidDestroy => @editorDestroyedCallback()

    @subs.add atom.commands.add @editorElement, 'slime:goto-definition': =>
      @openDefinition()
    @subs.add atom.commands.add @editorElement, 'slime:compile-function': =>
      @compileFunction()
    @subs.add atom.commands.add @editorElement, 'slime:compile-buffer': =>
      @compileBuffer()
    @subs.add atom.commands.add @editorElement, 'slime:macroexpand-1': =>
      @expand(false, true, false)
    @subs.add atom.commands.add @editorElement, 'slime:macroexpand': =>
      @expand(true, true, false)
    @subs.add atom.commands.add @editorElement, 'slime:macroexpand-all': =>
      @expand('all', true, false)
    @subs.add atom.commands.add @editorElement, 'slime:compiler-macroexpand-1': =>
      @expand(false, false, true)
    @subs.add atom.commands.add @editorElement, 'slime:compiler-macroexpand': =>
      @expand(true, false, true)
    @subs.add atom.commands.add @editorElement, 'slime:expand-1': =>
      @expand(false, true, true)
    @subs.add atom.commands.add @editorElement, 'slime:expand': =>
      @expand(true, true, true)

    # Pretend we just finished editing, so that way things get up to date
    @stoppedEditingCallback()

  dispose: ->
    @subs.dispose()

  stoppedEditingCallback: ->
    # Parse the file and get an abstract syntax tree, also get package
    @ast = paredit.parse(@editor.getText())
    @pkg = slime.getEditorPackage(@editor)

  cursorMovedCallback: ->
    # Implement a small 300ms delay until when we trigger that the cursor has moved
    if @mouseMoveTimeout
      clearTimeout @mouseMoveTimeout
    @mouseMoveTimeout = setTimeout ( => @processCursorMoved()), 310

  processCursorMoved: ->
    mouseMoveTimeout = null
    # Show slime autodocumentation
    # Get the current sexp we're in
    if @swank.connected
      sexp_info = @getCurrentSexp()
      if sexp_info
        promise = @swank.autodoc sexp_info.sexp, sexp_info.relativeCursor, @pkg
        if promise
          promise.then (response) => @statusView.displayAutoDoc response
        else
          @statusView.message ""

  # Return a string of the current sexp the user is in. The "deepest" one.
  # If we're not in one, return null.
  getCurrentSexp: ->
    index = @getCursorIndex()
    text = @editor.getText()
    return utils.getCurrentSexp(index, text, @ast)

  # Return the outermost sexp range!
  getOutermostSexp: ->
    index = @getCursorIndex()
    text = @editor.getText()
    range = paredit.navigator.rangeForDefun @ast, index
    if not range
      return null
    [start, end] = range
    sexp = text[start...end]
    return {sexp: sexp, start: start, end: end}


  openDefinition: ->
    if @swank.connected
      # Get either the currently selected word, or the current word under the cursor
      # (taking into account how Lisp parses word, which is different than many other languages!)
      word = @editor.getSelectedText()
      word = @editor.getWordUnderCursor({wordRegex: utils.lispWordRegex}) if word == ""
      console.log "Looking up: " + word

      @swank.find_definitions(word, @pkg).then (refs) =>
        bubble = new Bubble(atom.workspace.getActiveTextEditor(), refs)

    else
      atom.notifications.addWarning("Not connected to Lisp", detail:"Going to a definition requires querying the Lisp image. So connect to it first!")


  compileFunction: ->
    # Compile the function under the cursor
    console.log "Compile function"
    sexp = @getOutermostSexp()
    if sexp
      if @swank.connected
        # Retrieve the file & path (and error out if not saved yet)
        title = @editor.getTitle()
        path = @editor.getPath()
        if not path
          atom.notifications.addWarning("Please save this file before compiling.")
          return false

        # Convert the start and end of sexp to Atom Points
        p_start = utils.convertIndexToPoint(sexp.start, @editor)
        p_end = utils.convertIndexToPoint(sexp.end, @editor)

        # Find file's package
        pkg = slime.getEditorPackage(@editor, p_start)
        console.log("pkg = "+pkg)

        # Trigger a compilation
        line_reference = p_start.row + 1
        col_reference = p_start.column + 1
        @swank.compile_string(sexp.sexp, title, path, sexp.start, line_reference, col_reference, pkg)

        # Trigger the highlight effect
        range = Range(p_start, p_end)
        utils.highlightRange(range, @editor, delay=250)

  compileBuffer: ->
    # Compile the entire buffer
    if @swank.connected
      # Retrieve the path and error out if not saved yet
      path = @editor.getPath()
      if not path
        atom.notifications.addWarning("Please save this file before compiling.")
        return false

      # Trigger a compilation
      @swank.compile_file(path, @pkg, true)

      # Trigger the highlight effect
      utils.highlightRange(Range([0, 0], @convertIndexToPoint(@editor.getText().length - 1)), @editor, delay=250)

  expand_in_minibuffer: (minibuffer, repeatedly, macros, compiler_macros) ->
    index = utils.convertPointToIndex(minibuffer.getCursors()[0].getBufferPosition(), minibuffer)
    sexp = utils.getCurrentSexp(index, minibuffer.getText())
    if sexp
      @swank.expand(sexp.sexp, @pkg, repeatedly, macros, compiler_macros).then (result) ->
        [start, end] = sexp.range
        startPoint = utils.convertIndexToPoint(start, minibuffer)
        endPoint = utils.convertIndexToPoint(end, minibuffer)
        minibuffer.setTextInBufferRange([startPoint, endPoint], result, {})

  expand: (repeatedly, macros, compiler_macros) ->
    if @swank.connected
      sexp = @getCurrentSexp()
      if sexp
        @swank.expand(sexp.sexp, @pkg, repeatedly, macros, compiler_macros).then (result) =>
          editor = minibuffer.open("Expansion", result, atom.workspace.getBottomDock().getActivePane())

          subs = new CompositeDisposable
          editor.onDidDestroy () ->
            subs.dispose()

          editorElement = atom.views.getView(editor)
          subs.add atom.commands.add editorElement, 'slime:macroexpand-1': =>
            @expand_in_minibuffer(editor, false, true, false)
          subs.add atom.commands.add editorElement, 'slime:macroexpand': =>
            @expand_in_minibuffer(editor, true, true, false)
          subs.add atom.commands.add editorElement, 'slime:macroexpand-all': =>
            @expand_in_minibuffer(editor, 'all', true, false)
          subs.add atom.commands.add editorElement, 'slime:compiler-macroexpand-1': =>
            @expand_in_minibuffer(editor, false, false, true)
          subs.add atom.commands.add editorElement, 'slime:compiler-macroexpand': =>
            @expand_in_minibuffer(editor, true, false, true)
          subs.add atom.commands.add editorElement, 'slime:expand-1': =>
            @expand_in_minibuffer(editor, false, true, true)
          subs.add atom.commands.add editorElement, 'slime:expand': =>
            @expand_in_minibuffer(editor, true, true, true)
    else
      atom.notifications.addWarning("Not connected to Lisp!")

  editorDestroyedCallback: ->
    console.log "Closed!"

  getCursorIndex: ->
    point = @editor.getCursors()[0].getBufferPosition()
    return utils.convertPointToIndex(point, @editor)
