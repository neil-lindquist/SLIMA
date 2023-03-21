# SLIMA package

The Superior Lisp Interactive Mode for ~~Atom~~Pulsar.  This package allows you to interactively develop Common Lisp code, helping turn Pulsar into a full-featured Lisp IDE.  SLIMA uses the same Swank backend as Emacs's SLIME to control the Lisp process.

This project originated as a package for Atom, first under the name [atom-slime](https://github.com/sjlevine/atom-slime) then forked under the name SLIMA.
After Github announced the end of support for Atom, a community formed around a fork named [Pulsar](https://github.com/pulsar-edit/pulsar).
SLIMA should currently be compatible with both Atom and Pulsar, but future development of SLIMA will target Pulsar and break compatibility with Atom.



![screenshot](https://raw.githubusercontent.com/neil-lindquist/slima/master/media/slima-screenshot.png)

Current features of this package:

- Read-eval-print-loop (REPL) for interactive Lisp development
- Integrated debugger
- Jumping to a method definition
- Autocomplete suggestions based on your code
- "Compile this function"
- "Compile this file"
- Function method argument order documentation
- Integrated profiler
- Interactive object inspection

Future features:
- "Who calls this function" command
- Stepping debugger

Documentation for SLIMA's features can be found in the [project wiki](https://github.com/neil-lindquist/SLIMA/wiki).

**Note**: This package is still in active development! Contributions and bug reports are welcome.



Guide to setting up Pulsar as your main Lisp editor!
-------------------------------------------
By following these instructions, you can use Pulsar very effectively as your Lisp editor.

1. Install this `SLIMA` package from Pulsar.  Additionally, it is recommended to install the `language-lisp` package (syntax highlighting) and either the `lisp-paredit` or `parinfer` package or both (parenthesis editing).

2. Install a Common Lisp if you don't already have one (such as [SBCL](http://sbcl.org/platform-table.html)).

3. Download the source code for SLIME, which exists in a separate repository. Place it somewhere safe (you'll need it's location in the following step). Note that if you've used Emacs before, you may already have SLIME somewhere on your computer. Otherwise, you can download it from the [Github Repository](https://github.com/slime/slime/releases).  Additionally, SLIMA doesn't work with versions of SLIME older than v2.23.

4. After installing the `slima` package, go to its package preferences page within Pulsar. Under the "Lisp Process" field, enter the executable for your lisp (ex. `sbcl`. Note that on some platforms you may need the full pathname, such as `/usr/bin/sbcl`). Under the "SLIME Path" field, enter the path where you have SLIME on your computer from the above step.  Detailed information is available in [the SLIMA wiki](https://github.com/neil-lindquist/SLIMA/wiki/Configuring-the-Lisp-Process).

5. (Optional) Consider adding the following to your Pulsar keymap file.  This will allow the tab key to trigger automatic, correct indentation of your Lisp code (unless there's an autocomplete menu active).
```
'atom-text-editor[data-grammar~="lisp"]:not(.autocomplete-active)':
    'tab': 'lisp-paredit:indent'
```

6. (Optional) In Pulsar's `autocomplete-plus` package, consider changing the "Keymap For Confirming A Suggestion" option from "tab and enter" to just "tab". This makes autocomplete more amenable when using the REPL, so that pressing enter will complete your command rather than triggering autocomplete.

7. (Optional) In Pulsar's `bracket-matcher` package, consider unchecking the "Autocomplete Brackets" option. Both the `lisp-paredit` and `parinfer` packages above will take care of autocompleting parenthesis when you're editing a lisp file. Unchecking this option will prevent single quotes from being autocompleted in pairs, allowing you to define lisp symbols easier (for example, `(setf x 'some-symbol)`).

All done! Futher information on configuring the lisp process can be found in the [project wiki](https://github.com/neil-lindquist/SLIMA/wiki/Controlling-the-Lisp-Process-Lifecycle).


How to Edit Lisp code with Pulsar
----------------------------
Once you've followed the above steps, you should have:
- Syntax highlighting if you open a file ending in `.lisp`
- Proper lisp indentation when you hit tab

To start a REPL (an interactive terminal where you can interact with Lisp live), run the `Slime: Start` command from the command pallete. A REPL should then pop up. Note that if this is your first time using `slima`, or you've updated your lisp process, you may get some warning messages about not being able to connect. This is normal; wait a minute or so, then run `slime:connect`. (This happens because your lisp is compiling the swank server and isn't ready before this package times out).

With the REPL, you can type commands, see results, switch packages, and more. It's a great way to write Lisp code! A debugger will come up if an error occurs. You can also use the up & down arrows to scroll up through your past commands. Type <kbd>Ctrl</kbd>+<kbd>C</kbd> to interrupt lisp (if it's in an infinite loop, for example).  The result value of evaluated expressions can be inspected by placing the cursor there and pressing <kbd>Ctrl</kbd>+<kbd>I</kbd>.

If you've compiled your lisp code, placing the cursor over a method will cause a documentation string to appear at the bottom of the Pulsar window, showing you the function arguments and their order.

If you want to jump to where a certain method is defined, go to it and press <kbd>alt</kbd> + <kbd>.</kbd> (Mac: <kbd>ctrl</kbd> + <kbd>cmd</kbd> + <kbd>.</kbd>)or use the `Slime: Goto Definition` function in Pulsar. A little pop up window will come up and ask you which method you'd like to go to (since methods could be overloaded). Use the keyboard to go up and down, and press enter to jump to the definition you choose.

To compile a single toplevel form in a Lisp file, place the cursor somewhere in that form and press <kbd>alt</kbd>+<kbd>c</kbd> (Mac: <kbd>ctrl</kbd> + <kbd>cmd</kbd> + <kbd>c</kbd>). The form should glow momentarily to indicate it's compiling, and from then on you can use it in the REPL. To compile an entire buffer, place the cursor anywhere in that file and press <kbd>alt</kbd>+<kbd>k</kbd> (Mac: <kbd>ctrl</kbd> + <kbd>cmd</kbd> + <kbd>k</kbd>). The entire file will glow for a moment to indicate compilation.  Lastly, an individual form can be compiled using <kbd>alt</kbd>+<kbd>e</kbd> (Mac: <kbd>ctrl</kbd>+<kbd>cmd</kbd>+<kbd>e</kbd>).

To use the integrated profiler, run `Slime: Profile`. You should see a menu appear at the bottom of Pulsar, where you can select what you'd like to profile. For example, click "Function" and type the function name at the dialog to begin profiling. You may then click "Report" to print a report to the REPL with profiling information.

How it works
--------------
This package makes use of the superb work from the SLIME project. SLIME started as a way to integrate Lisp with Emacs, a popular text editor for Lisp. It works by starting what is known as a Swank server, which is code that runs in Lisp. Emacs then runs separately and connects to the Swank server. It's able to make remote procedure calls to the swank server to compile functions, lookup function definitions from your live code, and much more thanks to the fact that Lisp is such a dynamic language.

This package uses the Swank server from the SLIME project unchanged. This package allows Pulsar to speak the same protocol as Emacs for controlling the Swank server and integrating Lisp into the editor.
