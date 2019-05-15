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
