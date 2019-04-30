etch = require 'etch'
$ = etch.dom

module.exports =
  class StatusView

    constructor: ->
      @msg = 'Slime not connected.'
      etch.initialize @

    update: (props, children) ->
      return etch.update @

    render: () ->
      $.div {className:'inline-block', style:'max-width:100vw'},
        @msg

    message: (@msg) =>
      return etch.update @

    # Display prettily-formatted autodocumentation information
    displayAutoDoc: (msg) =>
      # msg is a paredit-parsed structure
      if msg.type == 'symbol'
        # It's probably the :not-available symbol, so clear the autodoc
        @message ""
        return

      doc = msg.source[2...-2] # Cut off being / end quotes and parens
      currentSymbol = doc.match /\S+(?=\s+<===)/g
      if currentSymbol != null
        currentSymbol = currentSymbol[0]

      fields = doc.split /\s+/g
      entries = ({classes:[], text:field} for field in fields when field != "===>" and field != "<===")
      for entry in entries
        if entry.text == currentSymbol
          entry.classes.push "slime-keyword-highlight"

        if entry.text.charAt(0) == "&"
          entry.classes.push "constant"

      entries[0].classes.push "entity"
      entries[0].classes.push "name"
      entries[0].classes.push "function"
      body = ['(', $.span {className:entries[0].classes.join(' ')}, entries[0].text]
      for i in [1..entries.length-1]
        body.push ' '
        body.push $.span {className:entries[i].classes.join(' ')}, ' '+entries[i].text
      body.push ')'
      @message $.div {style:'font-family:monospace'}, body


    attach: (@statusBar) ->
      @statusBar.addLeftTile(item: @element, priority: 100)

    # Tear down any state and detach
    destroy: ->
      @element.remove()
