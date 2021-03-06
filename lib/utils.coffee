{Range, Point} = require 'atom'
minibuffer = require './minibuffer'
paredit = require 'paredit.js'

module.exports =
  lispWordRegex: /^[	 ]*$|[^\s\(\)"',;#%&\|`…]+|[\/\\\(\)"':,\.;<>~!@#\$%\^&\*\|\+=\[\]\{\}`\?\-…]+/g

  toSwankPath: (atomPath) ->
    atomPrefix  = atom.config.get('slima.advancedSettings.atomFilePrefix')

    if atomPath.replace(/\\/g, '/').startsWith(atomPrefix.replace(/\\/g, '/'))
      swankPrefix = atom.config.get('slima.advancedSettings.swankFilePrefix')
      return swankPrefix + atomPath.substring(atomPrefix.length)
    else
      return atomPath

  fromSwankPath: (swankPath) ->
    swankPrefix = atom.config.get('slima.advancedSettings.swankFilePrefix')

    if swankPath.replace(/\\/g, '/').startsWith(swankPrefix.replace(/\\/g, '/'))
      atomPrefix  = atom.config.get('slima.advancedSettings.atomFilePrefix')
      return atomPrefix + swankPath.substring(swankPrefix.length)
    else
      return swankPath

  convertIndexToPoint: (index, editor) ->
    substr = editor.getText().substring(0, index)
    row = (substr.match(/\n/g) || []).length
    lineStart = substr.lastIndexOf("\n") + 1
    column = index - lineStart
    new Point(row, column)

  convertPointToIndex: (point, editor) ->
    range = new Range(new Point(0, 0), point)
    return editor.getTextInBufferRange(range).length

  highlightRange: (range, editor, delay=1000) ->
    # Highlight the given (Atom) range temporarily and fade out
    marker = editor.markBufferRange(range, invalidate: 'never')
    decoration = editor.decorateMarker(marker, type: 'highlight', class: 'slime-flash-highlight')
    setTimeout((->
      decoration.setProperties(type: 'highlight', class: 'slime-flash-highlight animated')
      setTimeout((-> marker.destroy()), 750)
      ), delay)

  # Computes the file and point of a source location
  getSourceLocation: (source_location) ->

    loc =
      source_file: null
      source_editor: null
      point: null

    if source_location.buffer_type == 'error'
      throw source_location.error

    if source_location.buffer_type == 'buffer' or source_location.buffer_type == 'buffer-and-file'
      # look through editors for an editor with a matching name
      for editor in atom.workspace.getTextEditors()
        if editor.getTitle() == source_location.buffer_name
          loc.source_editor = editor
          loc.source_file = editor.getPath()
          break
      unless loc.source_file
        if source_location.buffer_type == 'buffer-and-file'
          loc.source_file = @fromSwankPath(source_location.file)
        else
          throw Error('No file for buffer source location with title '+source_location.buffer_name)
    else if source_location.buffer_type == 'file'
      loc.editor_file = @fromSwankPath(source_location.file)
    else
      # TODO source-form
      # TODO zip
      throw Error('No file for source location of type ' + source_location.buffer_type)

    if source_location.position_type == 'line'
      row = source_location.position_line
      col = source_location.position_column ? 0
      loc.point = new Point(row, col)
    else if source_location.position_type == 'position'
      if loc.source_editor
        loc.point = loc.source_editor.getBuffer().positionForCharacterIndex(source_location.position_offset)
      else
        throw Error('Cannot use index position when editor not present')
    else
      #TODO function-name
      #TODO source-path
      #TODO method
      throw Error('Unsupported position type '+source_location.position_type)

    return loc


  # Display a source location
  showSourceLocation: (source_location, fallBackTitle) ->
    if source_location.buffer_type == 'error'
      editor_promise = Promise.reject(source_location.error)
    else if source_location.buffer_type == 'buffer' or source_location.buffer_type == 'buffer-and-file'
      # look through editors for an editor with a matching name
      for editor in atom.workspace.getTextEditors()
        if editor.getTitle() == source_location.buffer_name
          pane = atom.workspace.paneForItem(editor)
          pane.activate()
          pane.activateItem(editor)
          editor_promise = Promise.resolve(editor)
          break
      unless editor_promise
        if source_location.buffer_type == 'buffer-and-file'
          # fall back to file if nessacery
          editor_promise ?= atom.workspace.open(@fromSwankPath(source_location.file))
        else
          editor_promise ?= Promise.reject('No editor named '+source_location.buffer_name)
    else if source_location.buffer_type == 'file'
      editor_promise = atom.workspace.open(@fromSwankPath(source_location.file))
    else if source_location.buffer_type == 'source-form'
      editor = minibuffer.open(fallBackTitle, source_location.source_form, atom.workspace.getActivePane())
      editor_promise = Promise.resolve(editor)
    else
      # TODO zip
      editor_promise = Promise.reject('Unsupported source type given: "'+source_location.buffer_type+'"')

    #need source_location, so use a closure to pass it to the next part
    editor_promise.then (editor) ->
      if source_location.position_type == 'line'
        row = source_location.position_line
        col = source_location.position_column ? 0
        editor.setCursorBufferPosition(new Point(row, col))
      else if source_location.position_type == 'position'
        position = editor.getBuffer().positionForCharacterIndex(source_location.position_offset)
        editor.setCursorBufferPosition(position)
      else
        #TODO function-name
        #TODO source-path
        #TODO method
        Promise.reject('Unsupported position type given: "'+source_location.position_type+'"')


  getCurrentSexp: (index, text, ensureList=true, ast=paredit.parse(text)) ->
    if ast.errors?.length != 0
      return null #paredit can't parse the expression
    range = paredit.navigator.sexpRangeExpansion ast, index, index
    if not range
      return null
    [start, end] = range
    sexp = text[start...end]
    while ensureList and sexp.charAt(0) != '('
      range = paredit.navigator.sexpRangeExpansion ast, start, end
      if not range
        return null
      [start, end] = range
      sexp = text[start...end]
    return sexp: sexp, relativeCursor: index - start, range: [start, end]
