# Contains various useful Slime-related functions
module.exports =

  # Given an an abstract syntax tree,
  # parse out the package name!
  getEditorPackage: (editor, startPos) ->
    unless startPos?
      startPos = editor.getBuffer().getEndPosition()
    #                |    in-package symbol            |      | string| |char| | symbol package    | |s name|
    pkgRegex = /\(\s*(?:cl::?|common-lisp::?)?in-package\s*(?:"([^"]+)"|#\\(.)|(?:(?:#?|[^ ):]+:?):)?([^) ]+))\s*\)/i
    pkg = "CL-USER"
    editor.backwardsScanInBufferRange pkgRegex, [[0, 0], startPos], (match) ->
      # there is exactly one matching group

      if match.match[3]
        m3 = match.match[3]
        if m3.charAt(0) == '|' && m3.slice(-1) == '|'
          pkg = m3.slice(1, -1)
        else
          pkg = m3.toUpperCase()
      else
        pkg = match.match[1] || match.match[2]

    return pkg


  # Given an AST and the cursor index,
  # which top level form are we in?
  getTopLevelForm: (ast, index) ->
    node = (s for s in ast.children when index >= s.start and index <= s.end)[0] if ast.children
    return node
