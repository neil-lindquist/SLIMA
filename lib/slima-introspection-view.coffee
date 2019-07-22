{CompositeDisposable} = require 'atom'
etch = require 'etch'
$ = etch.dom

module.exports =
class IntrospectionView

  obj: null

  constructor: () ->
    etch.initialize @

  update: () ->
    etch.update @

  render: ->
    return $.div {}, '' unless @obj?

    header_content = @header.map (elt) =>
      if typeof elt == 'string'
        if elt == '\n'
          $.br {}, ''
        else
          elt
      else # typeof elt == 'array'
        if elt[0] == ':value'
          $.a {on:{click:(e)=>@show_part elt[2]}}, elt[1]
        else
          $.button {className:'inline-block-tight btn', on:{click:(e)=>@resolve_action elt[2]}}, elt[1]

    if @slots?
      slots = @slots.map elt =>
        $.li {}, elt.name + "  =  " + elt.value
      $.div {className:"slima-infoview padded"},
        $.button {className:'inline-block-tight btn', on:{click:@show_previous}}, 'Previous Object'
        $.button {className:'inline-block-tight btn', on:{click:@show_next}}, 'Next Object'
        $.h1 {}, @obj.title
        $.div {}, header_content
        $.h3 {}, Slots
        $.div {className:'select-list'},
          $.ol {className:'list-group mark-active'}, slots
    else
      $.div {className:"slima-infoview padded"},
        $.button {className:'inline-block-tight btn', on:{click:@show_previous}}, 'Previous Object'
        $.button {className:'inline-block-tight btn', on:{click:@show_next}}, 'Next Object'
        $.h1 {}, @obj.title
        $.div {}, header_content


  setup: (@swank, @obj, @replView) ->
    split_index = @obj.content.indexOf '--------------------'
    if split_index != -1
      @header = @obj.content.splice(0, split_index)
      raw_slots = @obj.content.splice(10 + split_index)

      @slots = []
      i = 0
      while raw_slots[i] != '\n'
        slot = {}
        slot.select_fun_id = raw_slots[i][2]
        slot.name = raw_slots[i+2][1]
        slot.introspect_id = raw_slots[i+2][2]
        value = raw_slots[i+5]
        if typeof value == 'string'
          slot.value = value
          slot.value_id = null
        else
          slot.value = value[1]
          slot.value_id = value[2]

        @slots.push(slot)
        i += 1

      # @slots_inheritance_sort_id = @obj.content[split_index + 3][2]
      # @slots_alphabet_sort_id = @obj.content[split_index + 6][2]
      # @slots_alpha_sort = @obj.content[split_index + 6][1] == '[X]'
      # @slots_set_value_id = raw_slots[i+1][2]
      # @slots_makeunbound_id = raw_slots[i+3][2]
    else
      @header = @obj.content
      @slots = null

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
