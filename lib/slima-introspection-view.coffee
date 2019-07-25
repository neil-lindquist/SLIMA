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

    if @slotGroups?
      body = [
        $.button {className:'inline-block-tight btn', on:{click:@show_previous}}, 'Previous Object'
        $.button {className:'inline-block-tight btn', on:{click:@show_next}}, 'Next Object'
        $.h1 {}, @obj.title
        $.div {}, header_content
        $.div {},
          $.input {type:'checkbox', checked:@slots_inheritance_grouped, on:{click:(e)=>@resolve_action @slots_inheritance_group_id}}, ''
          'Group by Inheritance '
          $.input {type:'checkbox', checked:@slots_alphabet_sorted, on:{click:(e)=>@resolve_action @slots_alphabet_sort_id}}, ''
          'Sort Alphabetically'
        $.div {},
          $.button {className:'inline-block-tight btn', on:{click:(e)=>@resolve_action @slots_set_value_id}}, 'Set Value'
          $.button {className:'inline-block-tight btn', on:{click:(e)=>@resolve_action @slots_makeunbound_id}}, 'Make Unbound'
      ]

      for group in @slotGroups
        slots = group.slots.map (slot) =>
          $.li {},
            $.input {type:'checkbox', checked:slot.selected, on:{click:(e)=>@resolve_action slot.select_fun_id}}, ''
            $.a {on:{click:(e)=>@show_part slot.introspect_id}}, slot.name
            "  =  "
            if slot.value_id?
              $.a {on:{click:(e)=>@show_part slot.value_id}}, slot.value
            else
              slot.value
        body.push $.h3 {}, group.name
        body.push $.div {className:'select-list'},
                    $.ol {className:'list-group mark-active'}, slots

      return $.div {className:"slima-infoview padded"}, body

    else
      $.div {className:"slima-infoview padded"},
        $.button {className:'inline-block-tight btn', on:{click:@show_previous}}, 'Previous Object'
        $.button {className:'inline-block-tight btn', on:{click:@show_next}}, 'Next Object'
        $.h1 {}, @obj.title
        $.div {}, header_content


  setup: (@swank, @obj, @replView) ->
    content = @obj.content.map (entry) ->
      if typeof entry == 'string'
        return entry.replace(/  /g, ' \xa0');
      else #typeof entry == array
        return [entry[0], entry[1].replace(/  /g, ' \xa0'), entry[2]]
    split_index = content.indexOf '--------------------'
    if split_index != -1
      @header = content.slice(0, split_index)
      raw_slots = content.slice(9 + split_index)

      i = 0
      @slotGroups = []
      while typeof raw_slots[i] == 'string'
        group = {name: raw_slots[i], slots:[]}
        @slotGroups.push(group)
        i += 2
        while raw_slots[i] != '\n'
          slot = {}
          slot.selected = raw_slots[i][1] == '[X]'
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

          group.slots.push(slot)
          i += 7
        i += 1

      @slots_inheritance_group_id = content[split_index + 3][2]
      @slots_inheritance_grouped = content[split_index + 3][1] == '[X]'
      @slots_alphabet_sort_id = content[split_index + 6][2]
      @slots_alphabet_sorted = content[split_index + 6][1] == '[X]'
      @slots_set_value_id = raw_slots[i][2]
      @slots_makeunbound_id = raw_slots[i+2][2]
    else
      @header = content
      @slotGroups = null

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
