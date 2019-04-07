{CompositeDisposable} = require 'atom'
{$, $$, TextEditorView, View, SelectListView, ScrollView} = require 'atom-space-pen-views'
FrameInfoView = require './slima-frame-info'

module.exports =
class DebuggerView extends ScrollView
  @content: ->
    @div outlet:"main", class:"slima-debugger padded", =>
      @h1 outlet:"errorTitle", =>
        @text "Error description"
      @h2 outlet:"errorType", class:"text-subtle", "   Error sub-text"
      @h3 "Restarts:"
      @div class:"select-list", =>
        @ol outlet:"restarts", class:'list-group mark-active', =>
          @li class:"", =>
            @button class:"inline-block-tight btn", "Option 1"
            @text "Description of option 1"
          @li class:"", =>
            @button class:"inline-block-tight btn", "Option 2"
            @text "Description of option 2"
          @li class:"", =>
            @button class:"inline-block-tight btn", "Option 3"
            @text "Description of option 3"
          @li class:"", =>
            @button class:"inline-block-tight btn", "Option 3"
            @text "Description of option 3"
      @h3 "Stack Trace:"
      @div class:"select-list", =>
        @ol outlet:"stackTrace", class:'list-group mark-active', start:"0", =>
          @li class:"", =>
            @text "Description of frame 1"
          @li class:"", =>
            @text "Description of frame 2"
          @li class:"", =>
            @text "Description of frame 3"

  setup: (@swank, @info, @replView) ->

    @errorTitle.html @info.title
    @errorType.html @info.type
    level = @info.level
    thread = @info.thread
    @active = true

    @restarts.empty()
    for restart, i in @info.restarts
      @restarts.append $$ ->
        @li class:"", =>
          @button class:'inline-block-tight restart-button btn', restartindex:i, restart.cmd
          @text i + ": " + restart.description

    this.find('.restart-button').on 'click', (event) =>
      restartindex = event.target.getAttribute('restartindex')
      @activate_restart(restartindex)

    @render_stack_trace(@info.stack_frames)

    @swank.debug_get_stack_trace(thread).then (stack_trace) =>
      @info.stack_frames = stack_trace
      @render_stack_trace(stack_trace)

  activate_restart: (restartindex) ->
    if @info.restarts.length > restartindex
      @activate = false
      @swank.debug_invoke_restart(@info.level, restartindex, @info.thread)

  abort: () -> @swank.debug_abort_current_level(@info.level, @info.thread)
  quit: () -> @swank.debug_escape_all @info.thread
  continue: () -> @swank.debug_continue @info.thread

  render_stack_trace: (trace) =>
    @stackTrace.empty()
    thread = @info.thread
    for frame, i in trace
      @stackTrace.append $$ ->
        @li class:"", =>
          @button class:'inline-block-tight frame-info-button btn', frame_index:frame.frame_number, thread:thread, "Frame Info"
          @text i + ": " + frame.description

    this.find('.frame-info-button ').on 'click', (event) =>
      @view_frame_click_handler event

  view_frame_click_handler: (event) ->
    frame_index = event.target.getAttribute('frame_index')
    thread = thread
    if not @frame_info?
      @frame_info = new FrameInfoView
    @frame_info.setup(@swank, @info, Number(frame_index), @)

    atom.workspace.open('slime://debug/'+@info.level+'/frame')


  getTitle: -> "Debugger"
  getURI: -> "slime://debug/"+@info.level
  isEqual: (other) ->
    other instanceof DebuggerView and other.info.level == @info.level
