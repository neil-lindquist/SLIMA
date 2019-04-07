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
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('slima')

  describe "when the package is activated", ->
    beforeEach ->
      waitsForPromise ->
        activationPromise

    it "instantiates correctly", ->
      expect(Slima.swank).toBeInstanceOf(Swank.Client)
      expect(Slima.views).not.toEqual(null)
      expect(Slima.subs).not.toEqual(null)

  describe "swank starter", ->
    it "Doesn't start with an invalid path", ->
      atom.config.set("slime.slimePath", "/tmp/")

      swankStarter = new SwankStarter
      expect(swankStarter.start()).toEqual(false)
      expect(swankStarter.process).toEqual(null)
