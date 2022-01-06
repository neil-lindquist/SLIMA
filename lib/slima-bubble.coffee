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

    active_view = atom.views.getView(atom.workspace.getActiveTextEditor())

    # Add subscriptions for important key events, and to close
    @subs.add atom.commands.add(active_view, 'core:move-down': (event) =>
      @selIndex = (@selIndex + 1) % @reference.length
      etch.update @
      event.stopImmediatePropagation()
    )
    @subs.add atom.commands.add(active_view, 'core:move-up': (event) =>
      @selIndex = (@selIndex - 1) %% @reference.length
      etch.update @
      event.stopImmediatePropagation()
    )

    destroy_func = (event) => @destroy()
    @subs.add atom.commands.add(active_view, 'core:cancel': destroy_func)
    @subs.add @editor.onDidChangeCursorPosition(destroy_func)

    open_func = (event)=>
      # Confirmed! Open that tab!
      utils.showSourceLocation(@reference[@selIndex].location,
                               'Source for '+@reference[@selIndex].label)
      @destroy()
      event.stopImmediatePropagation()
    @subs.add atom.commands.add(active_view, 'editor:newline': open_func)
    # If lisp-paredit exists and gets it first, then enter happens
    # TODO - better way to handle it? Priorities?
    @subs.add atom.commands.add(active_view, 'lisp-paredit:newline': open_func)

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
