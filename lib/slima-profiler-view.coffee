{CompositeDisposable} = require 'atom'
{makeDialog} = require './dialog'
etch = require 'etch'
$ = etch.dom


module.exports =
class ProfilerView
  constructor: (@swank, @views) ->
    @enabled = false
    @msg = $.div {}, ''
    etch.initialize @

  update: (props, children) ->
    return etch.update @

  render: () ->
    $.div {className:'inline-block', style:'max-width:100vw;margin-left:13px'}, @msg

  toggle: ->
    if @enabled
      @msg = ''
      @enabled = false
    else
      @msg = [
        $.b({}, 'Profile')
        ' ',
        $.a({href:"#", id:"prof-func", on:{click:@profile_function_click_handler}}, "Function"),
        ' · ',
        $.a({href:"#", id:"prof-pack", on:{click:@profile_package_click_handler}}, "Package"),
        ' · ',
        $.a({href:"#", id:"prof-unprof", on:{click:@unprofile_click_handler}}, "Unprofile All"),
        ' · ',
        $.a({href:"#", id:"prof-reset", on:{click:@reset_click_handler}}, "Reset Data"),
        ' · ',
        $.a({href:"#", id:"prof-report", on:{click:@report_click_handler}}, "Report"),
      ]
      @enabled = true
    etch.update @

  unprofile_click_handler: ->
    @swank.profile_invoke_unprofile_all(@views.repl.pkg)

  report_click_handler: ->
    @swank.profile_invoke_report(@views.repl.pkg)

  reset_click_handler: ->
    @swank.profile_invoke_reset(@views.repl.pkg)

  profile_function_click_handler: ->
    makeDialog("Enter Function", false)
    .then((func) => @swank.profile_invoke_toggle_function(func, @views.repl.pkg))

  profile_package_click_handler: ->
    makeDialog("Enter Package", true)
    .then(([pack, rec_calls, prof_meth]) =>
      @swank.profile_invoke_toggle_package(pack, rec_calls, prof_meth, @views.repl.pkg))

  attach: (@statusBar) ->
    @statusBar.addLeftTile(item: @element, priority: 9)

  destroy: ->
    @element.remove()

  getTitle: -> "Profiler"
  getURI: -> "slime://profile"
  isEqual: (other) ->
    other instanceof ProfilerView
