{CompositeDisposable} = require 'atom'
etch = require 'etch'
$ = etch.dom
{showSourceLocation} = require './utils'

module.exports =
class FrameInfoView

  constructor: () ->
    etch.initialize @

  update: () ->
    etch.update @

  render: ->
    #need to early exit if we haven't been setup yet
    return $.div {}, '' unless @info

    frame = @info.stack_frames[@frame_index]

    nav_btns = []
    if @frame_index > 0
      nav_btns.push @create_nav(0, @info.stack_frames[0].description, 'Stack Top')
     if @frame_index > 1
       i = @frame_index-1
       nav_btns.push @create_nav(i, @info.stack_frames[i].description, 'Up')
     last_index = @info.stack_frames.length - 1
     if @frame_index < last_index - 1
       i = @frame_index+1
       nav_btns.push @create_nav(i, @info.stack_frames[i].description, 'Down')
     if @frame_index < last_index
       nav_btns.push @create_nav(last_index, @info.stack_frames[last_index].description, 'Stack Bottom')

    $.div {className:'slima-debugger padded'},
      $.h1 {}, @frame_index + ': ' + frame.description
      $.div {className:'select-list'},
        $.ol {className:'list-group mark-active'}, nav_btns
      $.h3 {}, 'Local Variables'
      $.div {className:'select-list'},
        $.ol {class:'list-group mark-active'},
          if frame.locals? and frame.locals.length > 0
            ($.li {}, local.id + ': ' + local.name + ' = ' + local.value) for local, i in frame.locals
          else
            $.li {}, '<No locals>'
      if frame.catch_tags? and frame.catch_tags.length > 0
        $.div {className:'select-list'},
          $.h3 {}, 'Catch Tags'
          $.ol {class:'list-group mark-active'},
            ($.li i+': '+tag) for tag, i in frame.catch_tags
      else
        ''
      $.div {className:'select-list'},
        $.ol {className:'list-group mark-active'},
          $.li {},
            $.button {className:'inline-block-tight btn', on:{click:@display_source}}, 'View Frame Source'
          $.li {},
            $.button {className:'inline-block-tight btn', disable:frame.restartable, on:{click:@restart}}, 'Restart Frame'
          $.li {},
            $.button {className:'inline-block-tight btn', on:{click:@disassemble}}, 'Disassemble Frame'
        if @disassembleText
          $.div {},
            $.h3 {}, 'Disassembled'
            $.span {className:'slime-message'}, @disassembleText
        else
          ''
        $.ol {className:'list-group mark-active'},
          $.li {},
            $.input {className:'native-key-bindings debug-text-entry', type:'text', size:50, ref:'frameReturnValue'}, ''
          $.li {},
            $.button {className:'inline-block-tight btn', on:{click:@returnFromFrame}}, 'Return From Frame'
          $.li {},
            $.button {className:'inline-block-tight btn', on:{click:@evalInFrame}}, 'Eval in Frame'

  create_nav: (index, frame_description, label) ->
      $.li {},
        $.button {className:'inline-block-tight frame-navigation-button btn', on:{click:(event)=>@show_frame index}}, label
        index+': '+frame_description

  setup: (@swank, @info, @frame_index, @debugView) ->
    #etch.update @
    #TODO only get details if we don't already have them
    @swank.debug_stack_frame_details(@frame_index, @info.stack_frames, @info.thread).then () =>
      etch.update @

  show_frame: (i) ->
    if i != @frame_index
      @setup(@swank, @info, i, @debugView)

  show_first_frame: ->
    @show_frame 0
  show_last_frame: ->
    @show_frame @info.stack_frames.length - 1
  show_frame_up: ->
    if @frame_index > 0
      @show_frame @frame_index-1
  show_frame_down: ->
    if @frame_index < @info.stack_frames.length - 1
      @show_frame @frame_index+1

  display_source: () =>
    frame_index = @frame_index
    @swank.debug_frame_source(frame_index, @info.thread)
    .then showSourceLocation
    .catch (error) ->
      atom.notifications.addError 'Cannot show frame source: '+error

  disassemble: () =>
    @swank.debug_disassemble_frame(@frame_index, @info.thread).then (output) =>
      @disassembleText = output
      etch.update @

  restart: () =>
    @debugView.active = false
    @swank.debug_restart_frame(@frame_index, @info.thread)

  returnFromFrame: () =>
    @swank.debug_return_from_frame(@frame_index, @refs.frameReturnValue.value, @info.thread)
    .then () =>
      @debugView.active = false
    .catch (error) =>
      atom.notifications.addError error.message, dismissable:true

  evalInFrame: () =>
    input = @refs.frameReturnValue.value
    @refs.frameReturnValue.value = ''
    @swank.debug_eval_in_frame(@frame_index, input, @info.thread).then (result) =>
      replView = @debugView.replView
      replView.print_string_callback(result+'\n')
      replView.replPane.activateItem(replView.editor)

  getTitle: -> 'Frame Info'
  getURI: => 'slime://debug/' + @info.level + '/frame'
  isEqual: (other) =>
    other instanceof FrameInfoView and @info.level == other.info.level
