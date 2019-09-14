
# a base class for the various views that SLIMA uses
module.exports =
class InfoView

  currentPane: () =>
    return atom.workspace.paneForItem(@getItem())

  getItem: () =>
    @

  activate: (pane=null) =>
    pane ?= @currentPane()
    if pane?
      pane.activate()
      pane.activateItem(@getItem())

  destroy: () =>
    pane = @currentPane()
    if pane?
      pane.destroyItem(@getItem())
