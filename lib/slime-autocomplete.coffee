# Implements Slime autocompletion!
utils = require './utils'

module.exports =
  selector: '.source.lisp-repl, .source.lisp'
  disableForSelector: '.comment'
  disabled: false

  # This will take priority over the default provider, which has a priority of 0.
  # `excludeLowerPriority` will suppress any providers with a lower priority
  # i.e. The default provider will be suppressed
  inclusionPriority: 1
  excludeLowerPriority: true

  # Required: Return a promise, an array of suggestions, or null.
  getSuggestions: ({editor, bufferPosition}) ->
    prefix = @getPrefix(editor, bufferPosition)
    if @swank?.connected and !@disabled and prefix != ""
      return @swank.autocomplete(prefix, @repl.pkg).then (acs) ->
        return ({text: ac, replacementPrefix: prefix} for ac in acs)
    else
      return new Promise (resolve) ->
        resolve([])


  # A better prefix for Lisp
  getPrefix: (editor, bufferPosition) ->
    # Get the text for the line up to the triggered buffer position
    # If this is the REPL editor, start after the prompt -- otherwise, start
    # at the beginning of this line
    if editor.getTitle() == 'repl.lisp-repl'
      start_char = @repl?.prompt?.length
    else
      start_char = 0
    line = editor.getTextInRange([[bufferPosition.row, start_char], bufferPosition])
    # Match the regex to the line, and return the match
    matches = line.match(utils.lispWordRegex)
    return matches?[matches?.length - 1] or ''

  # (optional): called _after_ the suggestion `replacementPrefix` is replaced
  # by the suggestion `text` in the buffer
  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->
    undefined

  # (optional): called when your provider needs to be cleaned up. Unsubscribe
  # from things, kill any processes, etc.
  dispose: ->
    undefined

  setup: (@swank, @repl) ->
    undefined

  disable: () -> @disabled = true
  enable: () -> @disabled = false
