
# a base class for the various views that SLIMA uses
module.exports =
class InfoView

  findCurrentPane: () =>
    for pane in atom.workspace.getPanes()
      if pane.getItems().includes(@)
        return pane
    return null

  getItem: () =>
    @

  activate: () =>
    pane = @findCurrentPane()
    if pane?
      pane.activate()
      pane.activateItem(@getItem())

  destroy: () =>
    pane = @findCurrentPane()
    if pane?
      pane.destroyItem(@getItem())
