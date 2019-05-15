{Range, Point} = require 'atom'

module.exports =
  lispWordRegex: /^[	 ]*$|[^\s\(\)"',;#%&\|`…]+|[\/\\\(\)"':,\.;<>~!@#\$%\^&\*\|\+=\[\]\{\}`\?\-…]+/g

  indexToPoint: (index, src) ->
    substr = src.substring(0, index)
    row = (substr.match(/\n/g) || []).length
    lineStart = substr.lastIndexOf("\n") + 1
    column = index - lineStart
    {row: row, column: column}

  convertIndexToPoint: (index, editor) ->
    p = @indexToPoint(index, editor.getText())
    new Point(p.row, p.column)

  highlightRange: (range, editor, delay=1000) ->
    # Highlight the given (Atom) range temporarily and fade out
    marker = editor.markBufferRange(range, invalidate: 'never')
    decoration = editor.decorateMarker(marker, type: 'highlight', class: 'slime-flash-highlight')
    setTimeout((=>
      decoration.setProperties(type: 'highlight', class: 'slime-flash-highlight animated')
      setTimeout((=> marker.destroy()), 750)
      ), delay)

  # Display a source location
  showSourceLocation: (source_location) ->
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
      editor = atom.workspace.buildTextEditor()
      editor.setText(source_location.source_form)
      #change default title
      editor.getTitle = -> editor.getFileName() ? 'Frame ' + frame_index + ' Source'
      #change condition for save prompt for unsaved file
      editor_buffer = editor.getBuffer()
      editor_buffer.isModified = ->
        if editor_buffer.file?.existsSync()
          editor_buffer.buffer.isModified()
        else
          editor_buffer.getText() != source_location.source_form
      #add to active pane
      activePane = atom.workspace.getActivePane()
      activePane.addItem(editor)
      activePane.activateItem(editor)
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
        position = editor.getBuffer()
                         .positionForCharacterIndex(source_location.position_offset)
        editor.setCursorBufferPosition(position)
      else
        #TODO function-name
        #TODO source-path
        #TODO method
        Promise.reject('Unsupported position type given: "'+source_location.position_type+'"')
