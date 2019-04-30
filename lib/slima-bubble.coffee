etch = require 'etch'
$ = etch.dom
{CompositeDisposable, Range, Point} = require 'atom'
utils = require './utils'

module.exports =
class Bubble
  constructor: (@editor, @reference) ->
    return if @reference.length == 0

    @subs = new CompositeDisposable()
    @selIndex = 0

    etch.initialize @

    # Create an Atom marker at current cursor position, and decorate it with
    # the DOM element
    @marker = @editor.markBufferPosition(@editor.getCursorBufferPosition())
    @editor.decorateMarker(@marker, {
      type:'overlay',
      item: @element
    })

    # Add subscriptions for important key events, and to close
    @subs.add atom.commands.add(atom.views.getView(atom.workspace.getActiveTextEditor()), 'core:move-down': (event) =>
      @selIndex = (@selIndex + 1) % @reference.length
      etch.update @
      event.stopImmediatePropagation()
    )
    @subs.add atom.commands.add(atom.views.getView(atom.workspace.getActiveTextEditor()), 'core:move-up': (event) =>
      @selIndex = (@selIndex - 1) % @reference.length
      etch.update @
      event.stopImmediatePropagation()
    )
    @subs.add atom.commands.add(atom.views.getView(atom.workspace.getActiveTextEditor()), 'core:cancel': (event) =>
      @destroy()
    )
    @subs.add atom.commands.add(atom.views.getView(atom.workspace.getActiveTextEditor()), 'editor:newline': (event) =>
      # Confirmed! Open that tab!
      utils.openFileToIndex(@reference[@selIndex].filename, @reference[@selIndex].index)
      @destroy()
      event.stopImmediatePropagation()
    )
    # TODO - better way to handle this? Priorities? If lisp-paredit exists and getss it first, then enter happens
    @subs.add atom.commands.add(atom.views.getView(atom.workspace.getActiveTextEditor()), 'lisp-paredit:newline': (event) =>
      # Confirmed! Open that tab!
      utils.openFileToIndex(@reference[@selIndex].filename, @reference[@selIndex].index)
      @destroy()
      event.stopImmediatePropagation()
    )
    @subs.add @editor.onDidChangeCursorPosition( (event) =>
      @destroy()
    )

  update: ->
    etch.update @

  render: () ->
    # Create the DOM element from the references
    linkElements = []
    for ref in @reference
      label = ref.label.toLowerCase().replace('\n', '')
      className = 'bubble-message'
      if @selIndex == linkElements.length
        className = 'bubble-message active'
      le = $ 'bubble-message', {className:className},
             $.span {className:'bubble-message-item'},
                $ 'bubble-message-line', {className:'bubble-message-line'}, label
      linkElements.push(le)
    return $.div {id:'bubble-inline'}, linkElements


  destroy: () ->
    @marker?.destroy()
    @subs?.dispose()
