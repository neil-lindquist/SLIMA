{CompositeDisposable, Point, Range} = require 'atom'
fs = require 'fs'
os = require 'os'
path = require 'path'
InfoView = require './slima-info-view'
DebuggerView = require './slima-debugger-view'
FrameInfoView = require './slima-frame-info'
InspectorView = require './slima-introspection-view'
{makeDialog} = require './dialog'
paredit = require 'paredit.js'

module.exports =
class REPLView extends InfoView
  pkg: "CL-USER"
  prompt: "> "
  uneditableMarker: null
  preventUserInput: false
  inputFromUser: true
  showingPrompt: true
  reading_for_stdin_callback: null
  # Keep track of command history, for use with the up/down arrows
  previousCommands: []
  cycleIndex: null
  inspector: null

  constructor: (@swank) ->
    @prompt = @pkg + "> "
    @loadReplHistory()

  attach: () ->
    @subs = new CompositeDisposable
    @setupSwankSubscriptions()
    @createRepl()
    @setupDebugger()

  # Make a new pane / REPL text editor, or find one
  # that already exists
  createRepl: () ->
    @editor = null
    if @swank.process?.cwd
      uri = @swank.process.cwd
    else
      uri = os.homedir()
    uri = uri + path.sep + 'repl.lisp-repl'

    editors = atom.workspace.getTextEditors()
    for editor in editors
      if editor.getTitle() == 'repl.lisp-repl'
        # We found the editor! Now search for the pane it's in.
        allPanes = atom.workspace.getPanes()
        for pane in allPanes
          if editor in pane.getItems()
            # Found the pane too!
            @editor = editor
            @editorElement = atom.views.getView(@editor)

    if @editor
      fs.writeFileSync(uri, "")
      @setupRepl()
      return

    # Create a new pane and editor if we didn't find one
    replPane = atom.workspace.getBottomDock().getActivePane()

    fs.writeFileSync(uri, '')
    atom.workspace.createItemForURI(uri).then (editor) =>
      atom.workspace.getBottomDock().activate()
      replPane.activateItem(editor)
      replPane.activate()
      @editor = editor
      @editorElement = atom.views.getView(@editor)
      @setupRepl()


  # Set up the REPL GUI for use
  setupRepl: () =>
    # Make sure it's marked with the special REPL class - helps some of our keybindings!
    @editorElement.classList.add('slime-repl')
    # Clear the REPL
    @clearREPL()
    # Attach event handlers
    @subs.add atom.commands.add @editorElement, 'core:backspace': (event) =>
      if @preventUserInput
        event.stopImmediatePropagation()
        return
      # Check buffer position!
      selections = @editor.getSelectedBufferRanges()
      for selection in selections
        if selection.start.isEqual(selection.end)
          # no selection, need to check that the previous character is backspace-able
          point = selection.start
          if @uneditableMarker.getBufferRange().containsPoint(point)
            event.stopImmediatePropagation()
            return
        else
          # range selected, need to check that selection is backspace-able
          if @uneditableMarker.getBufferRange().intersectsWith(selection, true)
            event.stopImmediatePropagation()
            return

    @subs.add atom.commands.add @editorElement, 'core:delete': (event) =>
      if @preventUserInput
        event.stopImmediatePropagation()
        return
      selections = @editor.getSelectedBufferRanges()
      for selection in selections
        # need to check that both start and end of selection are valid
        if @uneditableMarker.getBufferRange().intersectsWith(selection, true)
          event.stopImmediatePropagation()
          return

    @subs.add atom.commands.add @editorElement, 'core:cut': (event) =>
      if @preventUserInput
        event.stopImmediatePropagation()
        return
      selections = @editor.getSelectedBufferRanges()
      for selection in selections
        # need to check that both start and end of selection are valid
        if @uneditableMarker.getBufferRange().intersectsWith(selection, true)
          event.stopImmediatePropagation()
          return

    # Prevent undo / redo
    @subs.add atom.commands.add @editorElement, 'core:undo': (event) => event.stopImmediatePropagation()
    @subs.add atom.commands.add @editorElement, 'core:redo': (event) => event.stopImmediatePropagation()

    @subs.add atom.commands.add @editorElement, 'editor:newline': (event) => @handleEnter(event)
    @subs.add atom.commands.add @editorElement, 'editor:newline-below': (event) => @handleEnter(event)

    @subs.add @editor.onWillInsertText (event) =>
      #console.log 'Insert: ' + event.text
      # console.log "Insert: #{event.text}"
      if @inputFromUser
        if @preventUserInput
          event.cancel()
        selections = @editor.getSelectedBufferRanges()
        for selection in selections
          if selection.start.isEqual(selection.end)
            # no selection, need to check that the previous character is backspace-able
            point = selection.start
            if point.isLessThan(@uneditableMarker.getBufferRange().end)
              event.cancel()
          else
            # range selected, need to check that selection is backspace-able
            if @uneditableMarker.getBufferRange().intersectsWith(selection, true)
              event.cancel()
              return

    # Set up up/down arrow previous command cycling. But don't do it
    # if the autocomplete window is active, don't take the event when core movements are enabled
    @subs.add atom.commands.add @editorElement, 'core:move-up': (event) =>
      if not (@isAutoCompleteActive() and atom.config.get('autocomplete-plus.useCoreMovementCommands'))
        @cycleBack()
        event.stopImmediatePropagation()
    @subs.add atom.commands.add @editorElement, 'core:move-down': (event) =>
      if not (@isAutoCompleteActive() and atom.config.get('autocomplete-plus.useCoreMovementCommands'))
        @cycleForward()
        event.stopImmediatePropagation()

    # jump to first character of editable region on the line with the prompt
    @subs.add atom.commands.add @editorElement, 'editor:move-to-first-character-of-line', (event) =>
      @editor.moveCursors @moveCursorToFirstCharacterOfLine
      event.stopImmediatePropagation()

    @subs.add atom.commands.add @editorElement, 'editor:select-to-first-character-of-line', (event) =>
      @editor.expandSelectionsBackward (selection) =>
        selection.modifySelection () => @moveCursorToFirstCharacterOfLine(selection.cursor)
      event.stopImmediatePropagation()


    # Add a clear command
    @subs.add atom.commands.add @editorElement, 'slime:clear-repl': (event) =>
      @clearREPL()
    # Add an interrupt command
    @subs.add atom.commands.add @editorElement, 'slime:interrupt-lisp': (event) =>
      if @swank.connected
        @swank.interrupt()

    # Add presentation inspection
    @subs.add atom.commands.add @editorElement, 'slime:inspect-presentation-context', {
        didDispatch: (event) =>
          clazzes = event.target.classList
          pid = null
          for clazz in clazzes
            match = ///^repl-presentation-(\d+)$///.exec(clazz)
            if match?
              pid = Number(match[1])
              break
          if pid?
            @swank.inspect_presentation(pid, @pkg)
            .then(@inspect)
        hiddenInCommandPalette: true
      }

    @subs.add atom.commands.add @editorElement, 'slime:inspect-presentation', (event) =>
      cursors = @editor.getCursorBufferPositions()
      for cursor in cursors
        for pid,marker of @presentationMarkers
          if marker.getBufferRange().containsPoint(cursor)
            @swank.inspect_presentation(pid, @pkg)
            .then(@inspect)
            return

    #debugger controls
    for i in [0..9]
      do (i) =>
        @addDebugCommand 'slime:debug-restart-'+i, (debug) -> debug.activate_restart(i)

    @addMenuCommand 'slime:menu-quit', ((debug) -> debug.quit()), ((frame) => frame.destroy()), (inspector) => inspector.destroy()
    @addMenuCommand 'slime:menu-next', null, ((frame) -> frame.show_frame_up()), ((inspector)->inspector.show_next())
    @addMenuCommand 'slime:menu-previous', null, ((frame) -> frame.show_frame_down()), ((inspector)->inspector.show_previous())

    @addDebugCommand 'slime:debug-abort', (debug) -> debug.abort()
    @addDebugCommand 'slime:debug-continue', (debug) -> debug.continue()
    @addDebugCommand 'slima:copy-debugger-info', (debug) -> debug.copy_debug_info()

    @addFrameInfoCommand 'slime:debug-show-frame-source', (frame) -> frame.display_source()
    @addFrameInfoCommand 'slime:debug-disassemble-frame', (frame) -> frame.disassemble()
    @addFrameInfoCommand 'slime:debug-frame-up', (frame) -> frame.show_frame_up()
    @addFrameInfoCommand 'slime:debug-frame-down', (frame) -> frame.show_frame_down()
    @addFrameInfoCommand 'slime:debug-last-frame', (frame) -> frame.show_last_frame()
    @addFrameInfoCommand 'slime:debug-first-frame', (frame) -> frame.show_first_frame()
    @addFrameInfoCommand 'slime:debug-restart-frame', (frame) -> frame.restart()


    @subs.add atom.workspace.addOpener (filePath) =>
      if filePath.match(///^slime://inspect/$///)
        unless @inspector
          @inspector = new InspectorView
        return @inspector

    @subs.add atom.workspace.onDidDestroyPaneItem (e) =>
      if e.item == @inspector
        @inspector = null


    @subs.add @editor.onDidDestroy =>
      @destroy()

    # Prevent the "do you want to save?" dialog from popping up when the REPL window is closed.
    # Unfortunately, as per https://discuss.atom.io/t/how-to-disable-do-you-want-to-save-dialog/31373
    # there is no built-in API to do this. As such, we must override an API method to trick
    # Atom into thinking it isn't ever modified.
    @editor.isModified = (() => false)


    # Hide the gutter(s)
    # g.hide() for g in @editor.getGutters()

    # @subs.add atom.commands.add 'atom-workspace', 'slime:thingy': =>
    #   point = @ed.getCursorBufferPosition()
    #   pointAbove = new Point(point.row - 1, @ed.lineTextForBufferRow(point.row - 1).length)
    #   @ed.setTextInBufferRange(new Range(pointAbove, pointAbove), "\nmonkus",undo:'skip')
    #   @ed.scrollToBotom()

  # registers a command for one or more menus
  addMenuCommand: (name, debugCommand, frameCommand, inspectorCommand) ->
    @subs.add atom.commands.add 'atom-workspace', name, {
        didDispatch: (event) => @callCurrentMenu(event, debugCommand, frameCommand, inspectorCommand)
        hiddenInCommandPalette: true
      }

  # registers a debug command
  # Note that these commands aren't displayed in the command palette, since they alias buttons
  addDebugCommand: (name, command) ->
    @subs.add atom.commands.add 'atom-workspace', name, {
        didDispatch: (event) => @callCurrentDebugger(event, command)
        hiddenInCommandPalette: true
      }
  # registers a frame info command
  # Note that these commands aren't displayed in the command palette, since they alias buttons
  addFrameInfoCommand: (name, command) ->
    @subs.add atom.commands.add 'atom-workspace', name, {
        didDispatch: (event) => @callCurrentFrameInfo(event, command)
        hiddenInCommandPalette: true
      }

  moveCursorToFirstCharacterOfLine: (cursor) =>
    screenRow = cursor.getScreenRow()
    editableStart = @uneditableMarker.getBufferRange().end
    if screenRow == @editor.screenPositionForBufferPosition(editableStart).row
      screenLineStart = @editor.clipScreenPosition([screenRow, 0], {
          skipSoftWrapIndentation:true
        })
      screenLineBufferRange = @editor.bufferRangeForScreenRange([screenLineStart,
                                                                 [screenRow, Infinity]])
      firstCharacterColumn = editableStart.column
      if firstCharacterColumn != cursor.getBufferColumn()
        targetBufferColumn = firstCharacterColumn
      else
        targetBufferColumn = screenLineBufferRange.start.column

      cursor.setBufferPosition([screenLineBufferRange.start.row, targetBufferColumn])
    else
      cursor.moveToFirstCharacterOfLine()

  # override info view function to use @editor instead
  getItem: () =>
    @editor

  isAutoCompleteActive: () ->
    return @editorElement.classList.contains('autocomplete-active')

  # updates uneditableMarker to everything that's been printed/typed so far
  updateUneditable: () ->
    range = @editor.getBuffer().getRange()
    @uneditableMarker = @editor.markBufferRange(range, {exclusive: true})

  markPrompt: (promptRange) ->
    @updateUneditable()
    syntaxRange = new Range(promptRange.start, [promptRange.end.row, promptRange.end.column-1])
    syntaxMarker = @editor.markBufferRange(syntaxRange, {exclusive: true})
    @editor.decorateMarker(syntaxMarker, {type: 'text', class:'syntax--repl-prompt syntax--keyword syntax--control syntax--lisp'})

  clearREPL: () ->
    #clear the old presentaiton markers
    for pid,marker of @presentationMarkers
      marker.destroy()
    @presentationMarkers = {}

    if @preventUserInput or @reading_for_stdin_callback
      @editor.setText ''
      @updateUneditable()
    else
      #Set the text to the prompt
      @editor.setText @prompt
      range = @editor.getBuffer().getRange()
      @markPrompt(range)
    @editor.moveToEndOfLine()

    marker = @editor.markBufferPosition(new Point(0, 0))
    @editor.decorateMarker marker, {type:'line',class:'repl-line'}


  # Adds non-user-inputted text to the REPL
  appendText: (text, colorTags=true) ->
    @inputFromUser = false
    range = @editor.insertText(text, {autoIndent:false,autoIndentNewline:false})
    if colorTags
      marker = @editor.markBufferRange(range, {exclusive: true})
      @editor.decorateMarker(marker, {type: 'text', class:'syntax--string syntax--quoted syntax--double syntax--lisp'})
    @inputFromUser = true

  # Retrieve the string of the user's input
  getUserInput: (text) ->
    lastrow = @editor.getLastBufferRow()
    lasttext = @editor.lineTextForBufferRow(lastrow)
    promptEnd = @uneditableMarker.getBufferRange().end
    range = new Range(promptEnd, [lastrow, lasttext.length])
    return @editor.getTextInBufferRange(range)


  handleEnter: (event) ->
    if @preventUserInput or !@swank.connected
      # Can't process it right now
      event.stopImmediatePropagation()
      return

    input = @getUserInput()

    unless @reading_for_stdin_callback
      ast = paredit.parse(input)
      if ast.errors.find((err) -> err.error.indexOf('but reached end of input') != -1)
        # missing ending parenthesis, use default system to add newline
        return

    # Push this command to the ring if applicable
    if input != '' and @previousCommands[@previousCommands.length - 1] != input
      @previousCommands.push input
    @cycleIndex = @previousCommands.length

    @preventUserInput = true
    @showingPrompt = false
    @editor.moveToBottom()
    @editor.moveToEndOfLine()
    @appendText('\n',false)
    if @reading_for_stdin_callback?
      @reading_for_stdin_callback(input+'\n')
      @reading_for_stdin_callback = null
    else # entered at prompt
      @swank.eval input, @pkg
      .then =>
        @insertPrompt()
        @preventUserInput = false
        @showingPrompt = true

    # Stop enter
    event.stopImmediatePropagation()



  insertPrompt: () ->
    @inputFromUser = false

    @editor.moveToBottom()
    @editor.moveToEndOfLine()

    @editor.insertText("\n", {autoIndent:false,autoIndentNewline:false})
    range = @editor.insertText(@prompt, {autoIndent:false,autoIndentNewline:false})[0]
    @markPrompt(range)

    # Now, mark it
    marker = @editor.markBufferPosition(range.start)
    @editor.decorateMarker marker, {type:'line',class:'repl-line'}

    @inputFromUser = true


  setupSwankSubscriptions: () ->
    # On changing package
    @swank.on 'new_package', @setPackage

    # On printing text from REPL response
    @swank.on 'print_string', (msg) =>
      @print_string_callback(msg)

    # On request for user input
    @swank.on 'read_from_minibuffer', (prompt, initial_value) ->
      return makeDialog(prompt, false, initial_value)

    @swank.on 'y_or_n_p', @y_or_n_p_resolver

    @swank.on 'read_string', (tag) =>
      # NOTE: Assuming that multiple read-string's will not happen at the same time
      @updateUneditable()
      @preventUserInput = false
      @activate()
      return new Promise (resolve, reject) =>
        @reading_for_stdin_callback = resolve

    @swank.on 'read_aborted', (tag) =>
      @reading_for_stdin_callback = null
      @preventUserInput = not @showingPrompt


    # On printing presentation visualizations (like for results)
    @presentation_starts = {}
    @presentationMarkers = {}
    @swank.on 'presentation_start', (pid) =>
      @presentation_starts[pid] = @editor.getBuffer().getRange().end
    @swank.on 'presentation_end', (pid) =>
      presentation_end = @editor.getBuffer().getRange().end
      range = new Range(@presentation_starts[pid], presentation_end)
      marker = @editor.markBufferRange(range, {exclusive: true})
      @editor.decorateMarker(marker, {type: 'text', class:'syntax--lisp repl-presentation repl-presentation-'+pid.toString()})
      @presentationMarkers[pid] = marker
      delete @presentation_starts[pid]

    # Debug functions
    @swank.on 'debug_setup', (obj) => @createDebugTab(obj)
    @swank.on 'debug_activate', (obj) =>
      @showDebugTab(Number(obj.level))
    @swank.on 'debug_return', (obj) =>
      @dbgv[Number(obj.level)-1].active = false
      @closeDebugTab(Number(obj.level))

    # Profile functions
    @swank.on 'profile_command_complete', (msg) =>
      atom.notifications.addSuccess(msg)


  y_or_n_p_resolver: (q, err=false) =>
    if err
      err_msg = 'Please enter "y" for yes or "n" for no'
    else
      err = null
    return makeDialog(q + ' (y or n)', false, '', err_msg)
    .then (answer) =>
      if answer.toLowerCase() == 'y'
        return true
      else if answer.toLowerCase() == 'n'
        return false
      else
        return @y_or_n_p_resolver(q, true)

  print_string_callback: (msg) ->
    # Print something to the REPL when the swank server says to.
    # However, we need to make sure we're not interfering with the cursor!
    if not @showingPrompt
      # A command is being run, no prompt is in the way - so directly print
      # anything received to the REPL
      @editor.moveToBottom()
      @editor.moveToEndOfLine()
      @appendText(msg)
    else
      # There's a REPL in the way - so go to the line before the REPL,
      # insert the message, then go back down to the corresponding line in the REPL!
      # But only move the user's cursor back to the REPL line if it was there to
      # begin with, otherwise put it back at it's absolute location.
      p_cursors = @editor.getCursorBufferPositions()
      original_prompt_end = @uneditableMarker.getBufferRange().end
      row_repl = original_prompt_end.row
      # Edge case: if the row is the last line, insert a new line right above then continue.
      if row_repl == 0
        @editor.setCursorBufferPosition([0, 0])
        @appendText("\n", colorTags=false)
        row_repl = 1
      # Compute the cursor position to the last character on the line above the REPL (we know it exists!)
      p_before_cursor = Point(row_repl - 1, @editor.lineTextForBufferRow(row_repl - 1).length)
      @editor.setCursorBufferPosition(p_before_cursor, {autoScroll: false})
      @appendText(msg)

      # Map cursors above the REPL to the same spot
      # Map cursors at the REPL based on the change in the prompt's end location
      new_prompt_end = @uneditableMarker.getBufferRange().end
      row_offset = new_prompt_end.row-original_prompt_end.row
      col_offset = Math.min(new_prompt_end.column-original_prompt_end.column, 0)
      p_cursors = for point in p_cursors
        if point.row < original_prompt_end.row
          point
        else
          [point.row+row_offset, point.column+col_offset]
      @editor.setCursorBufferPosition(p_cursors[0])
      for point in p_cursors[1..]
        @editor.addCursorAtBufferPosition(point)



  cycleBack: () ->
    if not @preventUserInput
      # Cycle back through command history
      @cycleIndex = @cycleIndex - 1 if @cycleIndex > 0
      @showPreviousCommand(@cycleIndex)


  cycleForward: () ->
    if not @preventUserInput
      # Cycle forward through command history
      @cycleIndex = @cycleIndex + 1 if @cycleIndex < @previousCommands.length
      @showPreviousCommand(@cycleIndex)


  showPreviousCommand: (index) ->
    if index >= @previousCommands.length
      # Empty it
      @setPromptCommand ''
    else if index >= 0 and index < @previousCommands.length
      cmd = @previousCommands[index]
      @setPromptCommand cmd


  setPromptCommand: (cmd) ->
    if @showingPrompt
      # Sets the command at the prompt
      lastrow = @editor.getLastBufferRow()
      lasttext = @editor.lineTextForBufferRow(lastrow)
      promptEnd = @uneditableMarker.getBufferRange().end
      range = new Range(promptEnd, [lastrow, lasttext.length])
      @editor.setTextInBufferRange(range, cmd)
      @editor.getBuffer().groupLastChanges()


  setupDebugger: () ->
    @dbgv = []
    process.nextTick =>
    @subs.add atom.workspace.addOpener (filePath) =>
      if filePath.match(///^slime://debug/\d+$///)
        level = filePath.slice(14)
        return @dbgv[level-1]
      if filePath.match(///^slime://debug/\d+/frame$///)
        level = filePath.slice(14, -6)
        return @dbgv[level-1].frame_info
    @subs.add atom.workspace.onWillDestroyPaneItem (e) =>
      if e.item in @dbgv
        level = e.item.info.level #1 based indices
        if level < @dbgv.length
          #recursively delete lower levels
          @closeDebugTab(level+1)
        if e.item.active
          e.item.abort()
          e.item.active = false
        e.item.frame_info?.destroy()


  createDebugTab: (obj) ->
    obj.level = Number(obj.level)
    if obj.level > @dbgv.length
      @dbgv.push(new DebuggerView)
    debug = @dbgv[obj.level-1]
    debug.setup(@swank, obj, @)

  showDebugTab: (level) ->
    # A slight pause is needed before showing for when an error occurs immediatly after resolving another error
    setTimeout(() =>
      if level == 1
        atom.workspace.open('slime://debug/'+level)
      else
        @dbgv[level-1].activate(@dbgv[level-2].currentPane())
    , 10)

  closeDebugTab: (level) ->
    @dbgv[level-1].destroy()
    @dbgv.pop()
    if level == 1
      @activate()


  inspect: (obj) =>
    if obj
      unless @inspector
        @inspector = new InspectorView
      @inspector.setup(@swank, obj, @)
      atom.workspace.open('slime://inspect/')

  callCurrentMenu: (event, debugCallback, frameCallback, inspectorCallback) =>
    activeItem = atom.workspace.getActivePaneItem()
    if debugCallback? and activeItem instanceof DebuggerView
      debugCallback(activeItem)
    else if frameCallback? and activeItem instanceof FrameInfoView and not event.target.classList.contains('debug-text-entry')
      frameCallback(activeItem)
    else if inspectorCallback? and activeItem instanceof InspectorView
      inspectorCallback(activeItem)
    else
      event.abortKeyBinding()

  callCurrentDebugger: (event, callback) =>
    activeItem = atom.workspace.getActivePaneItem()
    #TODO consider adding command to frame info views as well
    if activeItem instanceof DebuggerView
      callback(activeItem)
    else
      event.abortKeyBinding()

  callCurrentFrameInfo: (event, callback) =>
    activeItem = atom.workspace.getActivePaneItem()
    if activeItem instanceof FrameInfoView and not event.target.classList.contains('debug-text-entry')
      callback(activeItem)
    else
      event.abortKeyBinding()

  callInspector: (event, callback) =>
    activeItem = atom.workspace.getActivePaneItem()
    if activeItem instanceof InspectorView
      callback(activeItem)
    else
      event.abortKeyBinding()

  # Set the package and prompt
  setPackage: (pkg) =>
    @pkg = pkg
    @prompt = "#{@pkg}> "


  destroy: ->
    @saveReplHistory()
    if @swank.connected
      if @dbgv.length >= 1
        @closeDebugTab(1)
      @inspector?.destroy()
      @subs.dispose()
      @swank.quit()
    fs.unlinkSync(@editor.getPath())


  loadReplHistory: (showWarning=true) ->
    historyPath = os.homedir() + path.sep + '.slime-history.eld'
    return unless fs.existsSync(historyPath) && fs.statSync(historyPath).isFile()

    # Note that an encoding type of utf-8-unix is assumed
    rawHistory = fs.readFileSync(historyPath).toString()
    ast = paredit.parse(rawHistory)
    entries = ast.children.find (elt) -> elt.type == 'list'
    unless ast.errors.length == 0 && entries
      if showWarning
        atom.notifications.addWarning("Unable to parse history file")
      return

    oldCommands = []
    for entry in entries.children
      if entry.type == 'string'
        # remove leading and trailing quotes, then resolve escapes
        command = entry.source.slice(1, -1).replace(/\\("|\\)/g, "$1")
        oldCommands.push command
    @previousCommands = oldCommands.reverse().concat @previousCommands
    @cycleIndex = @previousCommands.length


  saveReplHistory: () ->
    # get the latest version if multiple SLIME sessions are going
    @loadReplHistory(false)
    outputCommands = []
    addedCommands = new Set()
    for i in [@previousCommands.length-1..0]
      command = @previousCommands[i]
      unless addedCommands.has command
        #only add items once
        outputCommands.push '"' + command.replace(/\\/g, "\\\\").replace(/"/g, "\\\"") + '"'
        addedCommands.add command

    historyPath = os.homedir() + path.sep + '.slime-history.eld'
    stream = fs.createWriteStream(historyPath);
    stream.once 'open', (fd) ->
      stream.write ";; -*- coding: utf-8-unix -*-\n;; History for SLIME REPL. Automatically written.\n;; Edit only if you know what you're doing\n"
      stream.write '(' + outputCommands.join(' ') + ')'
      stream.end()
