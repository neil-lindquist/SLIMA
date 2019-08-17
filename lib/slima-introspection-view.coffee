{CompositeDisposable} = require 'atom'
InfoView = require './slima-info-view'
etch = require 'etch'
$ = etch.dom

module.exports =
class IntrospectionView extends InfoView

  obj: null

  constructor: () ->
    etch.initialize @

  update: () ->
    etch.update @

  render: ->
    return $.div {}, '' unless @obj?
    $.div {className:"slima-infoview padded"},
      $.button {className:'inline-block-tight btn', on:{click:@show_previous}}, 'Previous Object'
      $.button {className:'inline-block-tight btn', on:{click:@show_next}}, 'Next Object'
      $.h1 {}, @obj.title
      $.div {className:'swank-formatted'}, @content


  setup: (@swank, @obj, @replView) ->
    @content = @obj.content.map (elt) =>
      if typeof elt == 'string'
        if elt == '--------------------'
          $.hr {}, ''
        else
          elt
      else #typeof elt == array
        text = elt[1]
        if elt[0] == ':value'
          $.a {on:{click:(e)=>@show_part elt[2]}}, text
        else if text == '[ ]'
          $.input {type:'checkbox', checked:false, on:{click:(e)=>@resolve_action elt[2]}}, ''
        else if text == '[X]'
          $.input {type:'checkbox', checked:true,  on:{click:(e)=>@resolve_action elt[2]}}, ''
        else
          if text.startsWith('[') and text.endsWith(']')
            text = text.slice(1, -1)
          $.button {className:'inline-block-tight btn', on:{click:(e)=>@resolve_action elt[2]}}, text

    etch.update @

  resolve_action: (id) =>
    @swank.inspector_call_nth_action(id, @replView.pkg)
    .then (obj) => @setup(@swank, obj, @replView) if obj

  show_part: (id) =>
    @swank.inspect_nth_part(id, @replView.pkg)
    .then (obj) => @setup(@swank, obj, @replView) if obj

  show_previous: () =>
    @swank.inspect_previous_object(@replView.pkg)
    .then (obj) => @setup(@swank, obj, @replView) if obj

  show_next: () =>
    @swank.inspect_next_object(@replView.pkg)
    .then (obj) => @setup(@swank, obj, @replView) if obj

  getTitle: -> "Inspector"
  getURI: -> "slime://inspect/"
  isEqual: (other) ->
    other instanceof IntrospectionView
