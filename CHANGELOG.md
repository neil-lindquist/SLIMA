## 2.8.3 (2023-03-20)
* Fix hang with newer versions of Swank (#58)
* Fix out of date content in the README

## 2.8.2 (2023-01-30)
* Change README now that Pulsar has replaced Atom
* Fix handling of presentations when the REPL prompt is present (#55)

## 2.8.1 (2022-01-06)
* Fix two bugs with the open definition command
  * A bad use of `@` causing an error (#52)
  * Moving the selector up from the top entry behaving incorrectly

## 2.8.0 (2021-06-20)
* Change the compile-file command to save the file, if modified
* Add the ability to use different pathnames between Atom and Swank (#51)

## 2.7.0 (2020-09-05)
* Add option to retain REPL content on Lisp restart (#45)
* Fix `slime:restart` and `slime:start` refusing to start a new Lisp session in some situations (#45)
* Refactor the organization of some internals

## 2.6.1 (2020-08-08)
* Fix bugs related to changing grammar to and from Lisp

## 2.6.0 (2020-05-27)
* Change the name of `slime:eval-expression` to `slime:eval-last-expression`
* Add command to inspect source forms
* Add some missing keystrokes to REPL
* Add function to evaluate a function call
* Add function to quit the swank server (#39)
* Add `SWANK_STARTER` environmental variable for custom swank server commands
* Fix `slime:disconnect` quitting the swank server instead of disconnecting (#39)
* Fix bugs related to history files
* Fix SLIMA-spawned Swank servers not use the port setting (#40)
* Fix a failure to load large inspectors (#37)

## 2.5.0 (2020-05-19)
* Add support for compiler notes (#31)
* Add command to evaluate a non-toplevel expression (#35)
* Add coffeelint-enforced style to SLIMA's source code
* Change a use of "Slime" with "SLIMA"
* Fix some issues when showing specific types of source locations
* Fix minor error when deactivating SLIMA without a lisp process

## 2.4.1 (2020-03-13)
* Fix error in compile file command (#33)

## 2.4.0 (2020-03-01)
* Add support for compiler-macro expansion and general expansion
* Add support for a codewalking macroexpand
* Change `macroexpand-all` to `macroexpand` to match SLIME
* Change some of the descriptions in SLIMA's settings
* Remove some unnecessary debugging prints

## 2.3.2 (2019-09-22)
* Fix the REPL not getting keyboard focus when the last debugger is closed (#32)
* Fix the lack of scroll bar when displaying a stack frame's source via source-form
* Fix the behavior of Clear REPL when the prompt isn't present
* Fix stack variable names being unnecessarily appended with `#0`

## 2.3.1 (2019-08-25)
* Change the inspector contents to be displayed as formatted by swank (#28)
* Change the behavior when swank requests user input to switch to the REPL tab (#27)
* Change the SLIMA tabs to spawn in the pane the user last placed them when able (#14)
* Fix bugs when the SLIMA tabs are not in the REPL's pane (#14)
* Fix the behavior of `*standard-output*` in multithreaded contexts (#26)
* Fix some minor bugs with closing the repl
* Fix the compile file command not loading the file (#29)

## 2.3.0 (2019-08-16)
* Change the <kbd>q</kbd> key to only close the current frame info tab, instead of quitting all errors
* Change the behavior of <kbd>home</kbd> to jump to the start of the user modifiable text in the REPL (#22)
* Change the REPL styling so that lines with prompts are no longer highlighted (#22)
* Add a context menu option to copy the information in a debugger (#24)
* Add a nice error message when the status bar fails to attach (#23)
* Fix multiline input not working
* Fix a bug that allowed certain modifications to the REPL when user input should have been disabled (#20)
* Fix frame info local variables being numbering strangely and displaying the wrong value when being inspected


## 2.2.0 (2019-07-28)
* Add support for the standard in in the REPL
* Add support for querying from swank via minibuffer and via an editor version of `y-or-n-p`
* Fix inspector bugs
  * grouping class slots would only show the first group
  * links were being added to some slot values that couldn't be inspected
  * the make slot unbound button was acting like set slot value
* Fix bugs with profiler input dialog


## 2.1.1 (2019-07-24)
* Change the repl-based functionality to use the REPL's current package
* Fix the compile-function not always recognizing `in-package` statements
* Fix a bug with printing `\"` from lisp
* Improve the inspector's presentation of whitespace-based formatting
* Fix the inspector not closing when the REPL is closed

## 2.1.0 (2019-07-20)
* Add an inspector
  * Add links from some locations in the debugger
  * Add <kbd>Ctrl</kbd>+<kbd>I</kbd> and context menu commands for returned values in the REPL.


## 2.0.2
* Fix debug tabs not spawning correctly in the new REPL location

## 2.0.1
* Place REPL in bottom dock, instead of emulating that behavior
* Disallow cycling the current command when the user cannot enter text
* Update swank-client to v2.0.3
  * Fixes the values of local variables in a stack frame being displayed as strings

## 2.0.0
* Use the current project's directory instead of the current file's as the Lisp
  process's initial working directory
* Fix problems with REPL when there is not a project
* Get Git tab to recognize the repository that the REPL is nested in
* Ensure the cursor is at the bottom of the REPL when printing the prompt or
  REPL output
* Fix autodoc failing to show functions/macros with 0 argument lambda lists



## 1.3.3
* Update swank-client to v2.0.2
  * Fixed a fatal bug with escaping arguments to autodoc

## 1.3.2
* Update swank-client to v2.0.1

## 1.3.1
* Fix bug in `debug_return_from_frame` and `debug_eval_in_frame`
* Improve handling of invalid formatting in the history file
* Support more source locations for `find_definition`
* Update swank-client to v2.0.0

## 1.3.0
* Add support for connecting to swank servers on other hosts/ports
* Save the command history between SLIMA sessions
* Replace space-pen with etch
* Update swank-client version to improve the function signature in the status bar


## 1.2.0
* Allow ~ as home directory in the slime path
* Add more commands to the Packages>SLIMA menu


## 1.1.3
* Support almost all string designators for compile string's package detection
* Allow presentations to be styled as normal lisp
* Allow REPL cycling to always work when autocomplete isn't using up/down

## 1.1.2
* Fix bug with debugger hotkeys trying to work in text editors
* Update swank-client version that ensures code is loaded after compiling

## 1.1.1
* Update swank-client version to support the continue restart keystroke

## 1.1.0
* Add keyboard shortcuts for debugger
* Add option to set the command for starting the swank server
* Allow slime path to be a lisp file
* Fix package detection for compile string


## 1.0.2
* Fixed a crash when unmatched double quotes are present in the REPL string

## 1.0.1
* Disabled commands that move lines in the REPL (#9)
* Fixed the improperly renamed menu
* Fixed a few issues based on how the REPL was created
* Improved the checks to ensure the prompt isn't edited
* Made the license information more accurate

## 1.0.0
* Forked [atom-slime](https://github.com/sjlevine/atom-slime)
* Reworked REPL internals
* Added support for multiline inputs
* Improved debugger
* Added compile file command
* Fix broken tests
