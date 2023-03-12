
module.exports = {
  open: function(title, text, pane) {
    let editor = atom.workspace.buildTextEditor({autoHeight: false});
    editor.setText(text);
    editor.getTitle = function() {
      return editor.getFileName() ?? title;
    };
    editor_buffer = editor.getBuffer();
    editor_buffer.isModified = function() {
      if (editor_buffer.file?.file.existsSync()) {
        return editor_buffer.buffer.isModified();
      } else {
        return editor_buffer.getText() !== text;
      }
    };
    pane.addItem(editor);
    pane.activateItem(editor);
    return editor;
  }
};
