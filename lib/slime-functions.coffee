# Contains various useful Slime-related functions
module.exports =

  # Given an an abstract syntax tree,
  # parse out the package name!
  getEditorPackage: (editor, startPos) ->
    unless startPos?
      startPos = editor.getBuffer().getEndPosition()
    #TODO add support for character names with more than one character
    pkgRegex = /\((?:cl:|common-lisp:)?in-package\s*(?:(?:'|#?:)?([^)]+)|"([^)]+)"|#\\(.))\s*\)/
    editor.backwardsScanInBufferRange pkgRegex, [[0,0], startPos], (match) ->
      # there is exactly one matching group
      return match.match[1] || match.match[2] || match.match[3]

    # couldn't find a in-package statement
    return "CL-USER"


  # Given an AST and the cursor index,
  # which top level form are we in?
  getTopLevelForm: (ast, index) ->
    node = (s for s in ast.children when index >= s.start and index <= s.end)[0] if ast.children
    return node
