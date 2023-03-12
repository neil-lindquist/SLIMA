module.exports = {
  getEditorPackage: function(editor, startPos) {
    if (startPos == null) {
      startPos = editor.getBuffer().getEndPosition();
    }
    //                  |  in-package symbol                 |      | string| |char| | symbol package     ||s name|
    const pkgRegex = /\(\s*(?:cl::?|common-lisp::?)?in-package\s*(?:"([^"]+)"|#\\(.)|(?:(?:#?|[^ ):]+:?):)?([^) ]+))\s*\)/i;
    let pkg = "CL-USER";
    editor.backwardsScanInBufferRange(pkgRegex, [[0, 0], startPos], function(match) {
      if (match.match[3]) {
        let m3 = match.match[3];
        if (m3.charAt(0) === '|' && m3.slice(-1) === '|') {
          return pkg = m3.slice(1, -1);
        } else {
          return pkg = m3.toUpperCase();
        }
      } else {
        return pkg = match.match[1] || match.match[2];
      }
    });
    return pkg;
  },
};
