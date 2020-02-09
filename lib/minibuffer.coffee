
module.exports =
  open: (title, text, pane) ->
    editor = atom.workspace.buildTextEditor({autoHeight: false})
    editor.setText(text)
    #change default title
    editor.getTitle = -> editor.getFileName() ? title
    #change condition for save prompt for unsaved file
    editor_buffer = editor.getBuffer()
    editor_buffer.isModified = ->
      if editor_buffer.file?.existsSync()
        editor_buffer.buffer.isModified()
      else
        editor_buffer.getText() != text
    #add to active pane
    pane.addItem(editor)
    pane.activateItem(editor)
    return editor
