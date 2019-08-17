
# a base class for the various views that SLIMA uses
module.exports =
class InfoView

  currentPane: () =>
    for pane in atom.workspace.getPanes()
      if pane.getItems().includes(@)
        return pane
    return null

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
