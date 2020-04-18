Slima = require '../lib/slima'
Swank = require 'swank-client'
SwankStarter = require '../lib/swank-starter'


# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

# SLIMA's dependancy on running a swank server makes tests harder
describe "Slima", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    # atom.config.set("slima.slimePath", "C:\\Users\\Neil\\Documents\\coding\\lisp\\Slime-Install\\slime-2.23\\")
    atom.config.set("slima.slimePath", process.env.TRAVIS_BUILD_DIR+"/slime")

    workspaceElement = atom.views.getView(atom.workspace)
    waitsForPromise ->
      atom.packages.activatePackage('slima')

  describe "when the package is activated", ->

    it "instantiates correctly", ->
      expect(Slima.swank).toBeInstanceOf(Swank.Client)
      expect(Slima.views).not.toEqual(null)
      expect(Slima.subs).not.toEqual(null)

      expect(Slima.views.statusView.getMessage()).toMatch(/SLIMA\s*not\s*connected/i)

  describe "start command", ->
    beforeEach ->
      waitsForPromise ->
        atom.commands.dispatch workspaceElement, "slime:start"

    it "Creates a REPL tab", ->
      expect(Slima.views.statusView.getMessage()).toMatch(/SLIMA\s*connected/i)

  describe "swank starter", ->
    it "Doesn't start with an invalid path", ->
      atom.config.set("slima.slimePath", "/tmp/")

      swankStarter = new SwankStarter
      expect(swankStarter.start()).toEqual(false)
      expect(swankStarter.process).toEqual(null)
