{CompositeDisposable} = require 'atom'
Dialog = require './dialog'
etch = require 'etch'
$ = etch.dom


module.exports =
class ProfilerView
  constructor: (@swank) ->
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
    @swank.profile_invoke_unprofile_all()

  report_click_handler: ->
    @swank.profile_invoke_report()

  reset_click_handler: ->
    @swank.profile_invoke_reset()

  profile_function_click_handler: ->
    func_dialog = new Dialog({prompt: "Enter Function", forpackage: false})
    func_dialog.attach(((func) => @swank.profile_invoke_toggle_function(func)), false)

  profile_package_click_handler: ->
    func_dialog = new Dialog({prompt: "Enter Package", forpackage: true})
    func_dialog.attach(((pack,rec_calls,prof_meth) => @swank.profile_invoke_toggle_package(pack,rec_calls,prof_meth)), true)

  attach: (@statusBar) ->
    @statusBar.addLeftTile(item: @element, priority: 9)

  destroy: ->
    @element.remove()

  getTitle: -> "Profiler"
  getURI: -> "slime://profile"
  isEqual: (other) ->
    other instanceof ProfilerView
