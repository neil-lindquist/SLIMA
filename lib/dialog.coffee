etch = require 'etch'
$ = etch.dom
{TextEditor} = require 'atom'

class Dialog

  rec_calls: true
  prof_meth: true

  constructor: (@prompt, @forpackage, initial_value, @errorMessage, @resolve_callback, @reject_callback) ->
    etch.initialize @
    atom.commands.add @element,
      'core:confirm': => @confirm()
      'core:cancel': => @cancel()
    @panel = atom.workspace.addModalPanel(item: this.element)
    @miniEditor().setText(initial_value)
    @miniEditor().element.focus()
    @miniEditor().scrollToCursorPosition()
    etch.update @

  update: (props, children) ->
    return etch.update @

  render: () ->
    $.div {},
      $.label {className:'icon'}, @prompt
      $(TextEditor, {
              ref: 'miniEditor',
              mini: true
            })
      if @errorMessage?
        $.div {className:'error-message'}, @errorMessage,
      else
        ''
      if @forpackage
        $.div {},
          $.label {className:'input-label'}, 'Record most common callers'
          $.input {className:'input-toggle', type:'checkbox', on:{click:@toggleRecCalls}, checked:true}
          $.label {className:'input-label', style:'margin-left: 13px'}, 'Profile methods'
          $.input {className:'input-toggle', type:'checkbox', on:{click:@toggleProfMeth}, checked:true}, ''
      else
        ''
      $.div {style:'text-align:right; display:block; margin-top: 13px'},
        $.button {className:'btn btn-primary icon icon-check', on:{click:@confirm}}
        $.button {className:'btn btn-error icon icon-x', on:{click:@close}}

  miniEditor: () -> @refs.miniEditor

  toggleRecCalls: =>
    @rec_calls = !@rec_calls

  toggleProfMeth: =>
    @prof_meth = !@prof_meth

  close: ->
    panelToDestroy = @panel
    @panel = null
    panelToDestroy?.destroy()
    atom.workspace.getActivePane().activate()

  confirm: () ->
    @close()

    txt = @miniEditor().getText()
    if @forpackage
      @resolve_callback([txt, @rec_calls, @prof_meth])
    else
      @resolve_callback(txt)


  cancel: ->
    @close()
    @reject_callback('cancel')


module.exports =
  makeDialog: (prompt, forpackage, initial_value='', errorMessage=null) ->
    return new Promise (resolve, reject) =>
      new Dialog(prompt, forpackage, initial_value, errorMessage, resolve, reject)
