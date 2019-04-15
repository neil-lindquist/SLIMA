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
