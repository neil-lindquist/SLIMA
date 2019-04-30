etch = require 'etch'
$ = etch.dom
{TextEditor} = require 'atom'

module.exports =
class Dialog

  errorMessage: ''

  constructor: (@prompt, @forpackage) ->
    etch.initialize @
    atom.commands.add @element,
      'core:confirm': => @confirm()
      'core:cancel': => @cancel()
    @miniEditor().onDidChange => @showError()

  update: (props, children) ->
    return etch.update @

  render: () ->
    $.div({}, [
      $.label({className:'icon'}, @prompt),
      $(TextEditor, {
              ref: 'miniEditor',
              mini: true
            }),
      $.div({className:'error-message'}, @errorMessage),
      (if @forpackage
        $.div({}, [
          $.label({className:'input-label'}, 'Record most common callers'),
          $.input({className:'input-toggle', type:'checkbox', on:{click:@toggleRecCalls}, checked:true}),
          $.label({className:'input-label', style:'margin-left: 13px'}, 'Profile methods'),
          $.input({className:'input-toggle', type:'checkbox', on:{click:@toggleProfMeth}, checked:true})
        ])
      else
        ''),
      $.div({style:'text-align:right; display:block; margin-top: 13px'}, [
        $.button({className:'btn btn-primary icon icon-check', on:{click:@confirm}}),
        $.button({className:'btn btn-error icon icon-x', on:{click:@close}})
      ])
    ])

  miniEditor: () -> @refs.miniEditor

  attach: (cb, forpackage) ->
    @callback = cb
    @panel = atom.workspace.addModalPanel(item: this.element)
    @miniEditor().element.focus()
    @miniEditor().scrollToCursorPosition()
    @forpackage = forpackage
    @rec_calls = true
    @prof_meth = true
    etch.update @


  toggleRecCalls: ->
    @rec_calls = !@rec_calls

  toggleProfMeth: ->
    @prof_meth = !@prof_meth

  close: ->
    panelToDestroy = @panel
    @panel = null
    panelToDestroy?.destroy()
    atom.workspace.getActivePane().activate()

  confirm: () ->
    txt = @miniEditor().getText()
    if @forpackage
      rc = {true: 't', false:'nil'}[@rec_calls]
      pm = {true: 't', false:'nil'}[@prof_meth]
      @callback(txt, rc, pm)
    else
      @callback(txt)
    @close()
    return

  cancel: ->
    @close()

  showError: (message='') ->
    @errorMessage = message
    #@flashError() if message
    etch.render @
