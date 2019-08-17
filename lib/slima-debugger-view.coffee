{CompositeDisposable} = require 'atom'
{clipboard} = require 'electron'
InfoView = require './slima-info-view'
FrameInfoView = require './slima-frame-info'
etch = require 'etch'
$ = etch.dom

module.exports =
class DebuggerView extends InfoView

  active: false

  constructor: () ->
    etch.initialize @

  update: () ->
    etch.update @

  render: ->
    #need to early exit if we haven't been setup yet
    return $.div {}, '' unless @active

    restarts = []
    for restart, i in @info.restarts
      restarts.push $.li {},
                      $.button {className:'inline-block-tight btn', on:{click:@restart_callback i}}, restart.cmd
                      i + ': ' + restart.description

    frames = []
    for frame in @info.stack_frames
      i = frame.frame_number
      frames.push $.li {},
                    $.button {className:'inline-block-tight btn', on:{click:@view_frame_callback i}}, 'Frame Info'
                    i + ': ' + frame.description

    $.div {className:'slima-infoview padded slima-debugger'},
      $.h1 {},
        $.a {on:{click:@inspect_condition}}, @info.title
      $.h2 {class:'text-subtle'}, @info.type
      $.h3 {}, 'Restarts:'
      $.div {className:'select-list'},
        $.ol {className:'list-group mark-active'}, restarts
      $.h3 {}, 'Stack Trace'
      $.div {className:'select-list'},
        $.ol {className:'list-group mark-active'}, frames

  setup: (@swank, @info, @replView) ->

    @active = true

    @swank.debug_get_stack_trace(@info.thread, @replView.pkg).then (stack_trace) =>
      @info.stack_frames = stack_trace
      etch.update @
    etch.update @

  #need to curry activate_restart to be able to generate restarts in a loop
  restart_callback: (restartindex) =>
    () =>
      @activate_restart restartindex

  #need to curry view_frame to be able to generate frames in a loop
  view_frame_callback: (frame_index) ->
    () =>
      if not @frame_info?
        @frame_info = new FrameInfoView
      @frame_info.setup(@swank, @info, Number(frame_index), @)

      atom.workspace.open('slime://debug/'+@info.level+'/frame', {location:"bottom"})

  activate_restart: (restartindex) ->
    if @info.restarts.length > restartindex
      @activate = false
      @swank.debug_invoke_restart(@info.level, restartindex, @info.thread, @replView.pkg)

  inspect_condition: () ->
    @swank.inspect_current_condition(@info.thread, @replView.pkg)
    .then @replView.inspect

  copy_debug_info: () ->
    clipboard.clear()
    restarts = ''
    for restart, i in @info.restarts
      restarts += '  ' + i + ': [' + restart.cmd + '] ' + restart.description + '\n'
    frames = ''
    for frame in @info.stack_frames
      frames += '  ' + frame.frame_number + ': ' + frame.description + '\n'
    clipboard.writeText(
      @info.title + '\n' +
      @info.type + '\n' +
      'Restarts: \n' +
      restarts +
      'Stack Trace: \n' +
      frames
    )

  abort: () -> @swank.debug_abort_current_level(@info.level, @info.thread, @replView.pkg)
  quit: () -> @swank.debug_escape_all @info.thread, @replView.pkg
  continue: () -> @swank.debug_continue @info.thread, @replView.pkg

  getTitle: -> "Debugger"
  getURI: -> "slime://debug/"+@info.level
  isEqual: (other) ->
    other instanceof DebuggerView and other.info.level == @info.level
