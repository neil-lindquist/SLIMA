{Range, Point} = require 'atom'
minibuffer = require './minibuffer'
paredit = require 'paredit.js'

module.exports =
  lispWordRegex: /^[	 ]*$|[^\s\(\)"',;#%&\|`…]+|[\/\\\(\)"':,\.;<>~!@#\$%\^&\*\|\+=\[\]\{\}`\?\-…]+/g

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
      if source_location.buffer_type == 'buffer-and-file'
        # fall back to file if nessacery
        editor_promise ?= atom.workspace.open(source_location.file)
      else
        editor_promise ?= Promise.reject('No editor named '+source_location.buffer_name)
    else if source_location.buffer_type == 'file'
      editor_promise = atom.workspace.open(source_location.file)
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
        col = location.position_column ? 0
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
