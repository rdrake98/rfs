// Messages

function displayMessage(text,file) {
  var msgs = $("#messageArea")
  if(!msgs.is(':parent'))
    createTiddlyButton(createTiddlyElement(msgs[0],"div",null,"messageToolbar"),
      "close", "close this message area", clearMessage)
  createTiddlyElement(msgs[0],"div",null,null,text)
  if(file) createExternalLink(msgs[0],file,file)
  msgs.show()
}

function clearMessage() { $("#messageArea").empty().hide() }

_dump = function(message) { console.log(message) }

dumpM = function(message) { displayMessage(message); _dump(message) }


var config = {}

// Browser detection. isSafari used just once
config.userAgent = navigator.userAgent.toLowerCase()
config.isSafari = config.userAgent.indexOf("applewebkit") > -1

config.options = {
  chkRegExp: false,
  chkCaseSensitive: false,
  chkTitleOnly: false,
  chkShowCreatedHistory: false,
  txtMaxEditRows: "30",
  txtWidth: "610",
  txtLinesRecentChanges: "75",
  txtCreatedShift: "0",
  txtMainTab: "Recent",
  txtMoreTab: "Shadowed",
}

config.optionsDesc = {
  txtMaxEditRows: "Maximum rows of edit box",
  txtWidth: "Width of images or videos",
  txtLinesRecentChanges: "Lines of Recent Changes",
}

// More messages (rather a legacy layout that should not really be like this)
config.views = {
  wikified: {},
  editor: {}
}

// Extensions
config.extensions = {}

// Macros; each has a 'handler' member that is inserted later
macros = {
  today: {},
  search: {},
  tiddler: {},
  permaview: {},
  option: {},
  newTiddler: {},
  tabs: {},
  message: {},
  view: {defaultView: "text"},
  edit: {},
  toolbar: {},
}

// Commands supported by the toolbar macro
commands = {
  closeTiddler: {},
  editTiddler: {},
  saveTiddler: {},
  cancelTiddler: {},
  deleteTiddler: {},
  top: {},
  drop: {},
  roll: {},
  expand: {},
  link: {},
  references: {type: "popup"},
}

// Basic regular expressions
textPrims = {
  upperLetter: "[A-Z\u00c0-\u00de\u0150\u0170]",
  lowerLetter: "[a-z0-9\u00df-\u00ff\u0151\u0171]",
  anyLetter:   "[A-Za-z0-9\u00c0-\u00de\u00df-\u00ff\u0150\u0170\u0151\u0171]",
  urlPattern: "(?:file|http|https|mailto|ftp|irc|news|data|txmt):[^\\s'\"]+(?:/|\\b)",
  unWikiLink: "~"
}
textPrims.wikiLink = "(?:(?:" + textPrims.upperLetter + "+" +
  textPrims.lowerLetter + "+" +
  textPrims.upperLetter +
  textPrims.anyLetter + "*)|(?:" +
  textPrims.upperLetter + "{2,}" +
  textPrims.lowerLetter + "+))"

textPrims.cssLookahead = "(?:(" + textPrims.anyLetter + "+)\\(([^\\)\\|\\n]+)(?:\\):))|(?:(" + textPrims.anyLetter + "+):([^;\\|\\n]+);)"
textPrims.cssLookaheadRegExp = new RegExp(textPrims.cssLookahead,"mg")

textPrims.brackettedLink = "\\[\\[([^\\]]+)\\]\\]"
textPrims.titledBrackettedLink = "\\[\\[([^\\[\\]\\|]+)\\|([^\\[\\]\\|]+)\\]\\]"
textPrims.tiddlerAnyLinkRegExp = new RegExp("(" +
  textPrims.wikiLink + ")|(?:" +
  textPrims.titledBrackettedLink + ")|(?:" +
  textPrims.brackettedLink + ")|(?:" +
  textPrims.urlPattern + ")","mg")

//--
//-- Shadow tiddlers
//--

config.shadowTiddlers = {}

messages = {dates: {}}

merge(messages,{
  macroError: "Error in macro <<%0>>",
  macroErrorDetails: "Error while executing macro <<%0>>:\n%1",
  missingMacro: "No such macro",
  overwriteWarning: "A tiddler named '%0' already exists. Choose OK to overwrite it",
})

messages.dates.months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
messages.dates.days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
messages.dates.shortMonths = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
messages.dates.shortDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
messages.dates.daySuffixes = ["st","nd","rd","th","th","th","th","th","th","th",
    "th","th","th","th","th","th","th","th","th","th",
    "st","nd","rd","th","th","th","th","th","th","th",
    "st"]
messages.dates.am = "am"
messages.dates.pm = "pm"

merge(macros.permaview,{
  label: "permaview",
  tooltip: "Link to an URL that retrieves all the currently displayed tiddlers"})

merge(commands.closeTiddler,{
  text: "close",
  tooltip: "Hide from view"})

merge(commands.editTiddler,{
  text: "edit",
  tooltip: "Edit this tiddler"})

merge(commands.saveTiddler,{
  text: "done",
  tooltip: "Save changes"})

merge(commands.cancelTiddler,{
  text: "back",
  tooltip: "Revert to normal view, undoing any changes"})

merge(commands.deleteTiddler,{
  text: "delete",
  tooltip: "Remove tiddler from wiki",
  warning: "Are you sure you want to delete '%0'?"})

merge(commands.references,{
  text: "references",
  tooltip: "Show tiddlers that link to this one"})

//--
//-- Main
//--

var params = null // Command line parameters
var store = null // TiddlyWiki storage
var story = null // Main story
var formatter = null // Default formatters, always used for the wikifier
var searchText = null
var searchRegex = null
var linkTarget = null
var startingUp = null
var tiddler // raises questions

function main()
{
  startingUp = true
  $(window).on('beforeunload', function() {
    return store.isDirty() || story.hasAnyChanges() || undefined
  })
  store = new TiddlyWiki()
  story = new Story("tiddlerDisplay","tiddler")
  addEvent(document,"click",Popup.onDocumentClick)
  var shadows = new TiddlyWiki()
  shadows.loadFromDiv("shadowArea")
  shadows.forEachTiddler(function(title,tiddler){
    config.shadowTiddlers[title] = tiddler.text
  })
  store.loadFromDiv("storeArea")
  loadOptions()
  loadHotkeys()
  $(document).bind('keydown','ctrl+f',findSelectionOuter)
  t0 = new Date()
  cacheTiddlerSplits()
  store.updateTiddlers()
  _dump("startup cacheTiddlerSplits and updateTiddlers: "+(new Date()-t0)+" ms")
  formatter = new Formatter(config.formatters)
  macros.unsavedChanges.reset()
  config.notifiers.forEach(n => n.notify(n.name))
  var hash = decodeURIComponent(location.hash.substr(1))
  var plusChanges = hash.slice(0,12) == "plusChanges*"
  var fromSelf = plusChanges && hash.slice(12) == "*"
  if(plusChanges && wikiType().length == 3) {
    ajaxPost('other_changes', {
        type: wikiType(),
        from_self: fromSelf,
      },
      function success(response) {
        var hash = JSON.parse(response)
        var changes = hash.tiddlers_changed.filter(h => !excludeTitle(h.title))
        dumpM("number of edits: " + changes.length)
        changes.forEach(function(h) {
          title = h.title || h
          var t = store.fetchTiddler(title)
          var medit = false
          if(!h.title) {
            action = t ? "deleted" : "not found"
            if(t) store.removeTiddler(title, true)
          } else if(!t || h.text != t.text) {
            action = t ? "changed" : "added"
            var modified = new Date(h.modified)
            var medited = h.fields.medited
            medited = medited && new Date(medited)
            medit = medited && medited > modified
            var latest = medited && medited > modified ? medited : modified
            if(t && latest < t.modified)
              dumpM("\n** newer " + title + " replaced by older **")
            store.saveTiddler(h.title,h.title,h.text,h.modifier,modified,
              h.fields,new Date(h.created),h.creator,true,medit)
          } else action = "unchanged"
          if(!medit) dumpM(title + " " + action)
        })
        displayInitialTiddlers(hash.tiddlers_open)
      },
      function fail() {
        _dump('other_changes')
        dumpM('failed in ruby')
        displayInitialTiddlers()
      }
    )
  } else
    displayInitialTiddlers(hash && !plusChanges ? hash.split(" ") : null)
}

function displayInitialTiddlers(titles) {
  if(!titles) {
    story.displayTiddler(null,"DefaultTiddlers")
    titles = story.getLinks("DefaultTiddlers")
    story.closeTiddler("DefaultTiddlers")
  }
  story.displayTiddlers(null, titles)
  scrollTo(0,0)
  refreshDisplay()
  document.title = getPageTitle()
  startingUp = false
}

ajaxPost = function(route, data, success, failure) {
  $.ajax('http://localhost:9898/public/' + route, {method: 'POST', data}).
    then(success, failure)
}

//--
//-- Formatter helpers
//--

function Formatter(formatters)
{
  this.formatters = []
  var pattern = []
  for(var n=0; n < formatters.length; n++) {
    pattern.push("(" + formatters[n].match + ")")
    this.formatters.push(formatters[n])
  }
  this.formatterRegExp = new RegExp(pattern.join("|"),"mg")
}

config.formatterHelpers = {
  inlineCssHelper: function(w)
  {
    var styles = []
    textPrims.cssLookaheadRegExp.lastIndex = w.nextMatch
    var lookaheadMatch = textPrims.cssLookaheadRegExp.exec(w.source)
    while(lookaheadMatch && lookaheadMatch.index == w.nextMatch) {
      if(lookaheadMatch[1]) {
        var s = lookaheadMatch[1].unDash()
        var v = lookaheadMatch[2]
      } else {
        s = lookaheadMatch[3].unDash()
        v = lookaheadMatch[4]
      }
      if(s=="bgcolor") s = "backgroundColor"
      if(s=="float") s = "cssFloat"
      styles.push({style: s, value: v})
      w.nextMatch = lookaheadMatch.index + lookaheadMatch[0].length
      textPrims.cssLookaheadRegExp.lastIndex = w.nextMatch
      lookaheadMatch = textPrims.cssLookaheadRegExp.exec(w.source)
    }
    return styles
  },

  applyCssHelper: function(e,styles)
  {
    for(var t=0; t < styles.length; t++)
      try {
        e.style[styles[t].style] = styles[t].value
      } catch (ex) {
      }
  },

  enclosedTextHelper: function(w)
  {
    this.lookaheadRegExp.lastIndex = w.matchStart
    var lookaheadMatch = this.lookaheadRegExp.exec(w.source)
    if(lookaheadMatch && lookaheadMatch.index == w.matchStart) {
      var text = lookaheadMatch[1]
      createTiddlyElement(w.output,this.element,null,null,text)
      w.nextMatch = lookaheadMatch.index + lookaheadMatch[0].length
    }
  },
}

isUrl = function(link)
{
  return new RegExp(textPrims.urlPattern,"mg").exec(link)
}

isExternalLink = function(link)
{
  if(store.isAvailable(link)) return false
  if(isUrl(link)) return true
  if(link.indexOf(".")!=-1 || link.indexOf("/")!=-1) return true
  return false
}

//--
//-- Standard formatters
//--

config.formatters = [
{
  // table
  match: "^\\|(?:[^\\n]*)\\|(?:[fhck]?)$",
  lookaheadRegExp: /^\|([^\n]*)\|([fhck]?)$/mg,
  rowTermRegExp: /(\|(?:[fhck]?)$\n?)/mg,
  cellRegExp: /(?:\|([^\n\|]*)\|)|(\|[fhck]?$\n?)/mg,
  cellTermRegExp: /((?:\x20*)\|)/mg,
  rowTypes: {"c":"caption", "h":"thead", "":"tbody", "f":"tfoot"},
  handler: function(w)
  {
    var table = createTiddlyElement(w.output,"table",null,"twtable")
    var prevColumns = []
    var currRowType = null
    var rowContainer
    var rowCount = 0
    var onmouseover = function() {$(this).addClass("hoverRow")}
    var onmouseout = function() {$(this).removeClass("hoverRow")}
    w.nextMatch = w.matchStart
    this.lookaheadRegExp.lastIndex = w.nextMatch
    var lookaheadMatch = this.lookaheadRegExp.exec(w.source)
    while(lookaheadMatch && lookaheadMatch.index == w.nextMatch) {
      var nextRowType = lookaheadMatch[2]
      if(nextRowType == "k") {
        table.className = lookaheadMatch[1]
        w.nextMatch += lookaheadMatch[0].length+1
      } else {
        if(nextRowType != currRowType) {
          rowContainer = createTiddlyElement(table,this.rowTypes[nextRowType])
          currRowType = nextRowType
        }
        if(currRowType == "c") {
          // Caption
          w.nextMatch++
          if(rowContainer != table.firstChild)
            table.insertBefore(rowContainer,table.firstChild)
          rowContainer.setAttribute("align",rowCount == 0?"top":"bottom")
          w.subWikifyTerm(rowContainer,this.rowTermRegExp)
        } else {
          var theRow = createTiddlyElement(rowContainer,"tr",null,rowCount%2?"oddRow":"evenRow")
          theRow.onmouseover = onmouseover
          theRow.onmouseout = onmouseout
          this.rowHandler(w,theRow,prevColumns)
          rowCount++
        }
      }
      this.lookaheadRegExp.lastIndex = w.nextMatch
      lookaheadMatch = this.lookaheadRegExp.exec(w.source)
    }
  },
  rowHandler: function(w,e,prevColumns)
  {
    var col = 0
    var colSpanCount = 1
    var prevCell = null
    this.cellRegExp.lastIndex = w.nextMatch
    var cellMatch = this.cellRegExp.exec(w.source)
    while(cellMatch && cellMatch.index == w.nextMatch) {
      if(cellMatch[1] == "~") {
        // Rowspan
        var last = prevColumns[col]
        if(last) {
          last.rowSpanCount++
          last.element.setAttribute("rowspan",last.rowSpanCount)
          last.element.valign = "center"
          if(colSpanCount > 1) {
            last.element.setAttribute("colspan",colSpanCount)
            colSpanCount = 1
          }
        }
        w.nextMatch = this.cellRegExp.lastIndex-1
      } else if(cellMatch[1] == ">") {
        // Colspan
        colSpanCount++
        w.nextMatch = this.cellRegExp.lastIndex-1
      } else if(cellMatch[2]) {
        // End of row
        if(prevCell && colSpanCount > 1)
          prevCell.setAttribute("colspan",colSpanCount)
        w.nextMatch = this.cellRegExp.lastIndex
        break
      } else {
        // Cell
        w.nextMatch++
        var styles = config.formatterHelpers.inlineCssHelper(w)
        var spaceLeft = false
        var chr = w.source.substr(w.nextMatch,1)
        while(chr == " ") {
          spaceLeft = true
          w.nextMatch++
          chr = w.source.substr(w.nextMatch,1)
        }
        var cell
        if(chr == "!") {
          cell = createTiddlyElement(e,"th")
          w.nextMatch++
        } else {
          cell = createTiddlyElement(e,"td")
        }
        prevCell = cell
        prevColumns[col] = {rowSpanCount:1,element:cell}
        if(colSpanCount > 1) {
          cell.setAttribute("colspan",colSpanCount)
          colSpanCount = 1
        }
        config.formatterHelpers.applyCssHelper(cell,styles)
        w.subWikifyTerm(cell,this.cellTermRegExp)
        if(w.matchText.substr(w.matchText.length-2,1) == " ") // spaceRight
          cell.align = spaceLeft ? "center" : "left"
        else if(spaceLeft)
          cell.align = "right"
        w.nextMatch--
      }
      col++
      this.cellRegExp.lastIndex = w.nextMatch
      cellMatch = this.cellRegExp.exec(w.source)
    }
  }
},

{
  // heading
  match: "^!{1,6}",
  termRegExp: /(\n)/mg,
  handler: function(w)
  {
    w.subWikifyTerm(createTiddlyElement(w.output,"h" + w.matchLength),this.termRegExp)
  }
},

{
  // list
  match: "^(?:[\\*#;:]+)",
  lookaheadRegExp: /^(?:(?:(\*)|(#)|(;)|(:))+)/mg,
  termRegExp: /(\n)/mg,
  handler: function(w)
  {
    var stack = [w.output]
    var currLevel = 0, currType = null
    var listLevel, listType, itemType, baseType
    w.nextMatch = w.matchStart
    this.lookaheadRegExp.lastIndex = w.nextMatch
    var lookaheadMatch = this.lookaheadRegExp.exec(w.source)
    while(lookaheadMatch && lookaheadMatch.index == w.nextMatch) {
      if(lookaheadMatch[1]) {
        listType = "ul"
        itemType = "li"
      } else if(lookaheadMatch[2]) {
        listType = "ol"
        itemType = "li"
      } else if(lookaheadMatch[3]) {
        listType = "dl"
        itemType = "dt"
      } else if(lookaheadMatch[4]) {
        listType = "dl"
        itemType = "dd"
      }
      if(!baseType)
        baseType = listType
      listLevel = lookaheadMatch[0].length
      w.nextMatch += lookaheadMatch[0].length
      var t
      if(listLevel > currLevel)
        for(t=currLevel; t < listLevel; t++) {
          var target = (currLevel == 0) ?
            stack[stack.length-1] : stack[stack.length-1].lastChild
          stack.push(createTiddlyElement(target,listType))
        }
      else if(listType!=baseType && listLevel==1) {
        w.nextMatch -= lookaheadMatch[0].length
        return
      } else if(listLevel < currLevel)
        for(t=currLevel; t>listLevel; t--)
          stack.pop()
      else if(listLevel == currLevel && listType != currType) {
        stack.pop()
        stack.push(createTiddlyElement(stack[stack.length-1].lastChild,listType))
      }
      currLevel = listLevel
      currType = listType
      var e = createTiddlyElement(stack[stack.length-1],itemType)
      w.subWikifyTerm(e,this.termRegExp)
      this.lookaheadRegExp.lastIndex = w.nextMatch
      lookaheadMatch = this.lookaheadRegExp.exec(w.source)
    }
  }
},

{
  // quoteByBlock
  match: "^<<<\\n",
  termRegExp: /(^<<<(\n|$))/mg,
  element: "blockquote",
  handler: function(w)
  {
    w.subWikifyTerm(createTiddlyElement(w.output,this.element),this.termRegExp)
  },
},

{
  // quoteByLine
  match: "^>+",
  lookaheadRegExp: /^>+/mg,
  termRegExp: /(\n)/mg,
  element: "blockquote",
  handler: function(w)
  {
    var stack = [w.output]
    var currLevel = 0
    var newLevel = w.matchLength
    var t,matched
    do {
      if(newLevel > currLevel) {
        for(t=currLevel; t < newLevel; t++)
          stack.push(createTiddlyElement(stack[stack.length-1],this.element))
      } else if(newLevel < currLevel) {
        for(t=currLevel; t>newLevel; t--)
          stack.pop()
      }
      currLevel = newLevel
      w.subWikifyTerm(stack[stack.length-1],this.termRegExp)
      createTiddlyElement(stack[stack.length-1],"br")
      this.lookaheadRegExp.lastIndex = w.nextMatch
      var lookaheadMatch = this.lookaheadRegExp.exec(w.source)
      matched = lookaheadMatch && lookaheadMatch.index == w.nextMatch
      if(matched) {
        newLevel = lookaheadMatch[0].length
        w.nextMatch += lookaheadMatch[0].length
      }
    } while(matched)
  }
},

{
  // rule
  match: "^----+$\\n?|<hr ?/?>\\n?",
  handler: function(w)
  {
    createTiddlyElement(w.output,"hr")
  }
},

{
  // monospacedByLine
  match: "^(?:/\\*\\{\\{\\{\\*/|\\{\\{\\{|//\\{\\{\\{|<!--\\{\\{\\{-->)\\n",
  element: "pre",
  handler: function(w)
  {
    switch(w.matchText) {
    case "/*{{{*/\n": // CSS
      this.lookaheadRegExp = /\/\*\{\{\{\*\/\n*((?:^[^\n]*\n)+?)(\n*^\f*\/\*\}\}\}\*\/$\n?)/mg
      break
    case "{{{\n": // monospaced block
      this.lookaheadRegExp = /^\{\{\{\n((?:^[^\n]*\n)+?)(^\f*\}\}\}$\n?)/mg
      break
    case "//{{{\n": // plugin
      this.lookaheadRegExp = /^\/\/\{\{\{\n\n*((?:^[^\n]*\n)+?)(\n*^\f*\/\/\}\}\}$\n?)/mg
      break
    case "<!--{{{-->\n": //template
      this.lookaheadRegExp = /<!--\{\{\{-->\n*((?:^[^\n]*\n)+?)(\n*^\f*<!--\}\}\}-->$\n?)/mg
      break
    default:
      break
    }
    config.formatterHelpers.enclosedTextHelper.call(this,w)
  }
},

{
  // wikifyComment
  match: "^(?:/\\*\\*\\*|<!---)\\n",
  handler: function(w)
  {
    var termRegExp = (w.matchText == "/***\n") ? (/(^\*\*\*\/\n)/mg) : (/(^--->\n)/mg)
    w.subWikifyTerm(w.output,termRegExp)
  }
},

{
  // macro
  match: "<<",
  lookaheadRegExp: /<<([^>\s]+)(?:\s*)((?:[^>]|(?:>(?!>)))*)>>/mg,
  handler: function(w)
  {
    this.lookaheadRegExp.lastIndex = w.matchStart
    var lookaheadMatch = this.lookaheadRegExp.exec(w.source)
    if(lookaheadMatch && lookaheadMatch.index == w.matchStart && lookaheadMatch[1]) {
      w.nextMatch = this.lookaheadRegExp.lastIndex
      invokeMacro(w.output,lookaheadMatch[1],lookaheadMatch[2],w,w.tiddler)
    }
  }
},

{
  // prettyLink
  match: "\\[\\[",
  lookaheadRegExp: /\[\[(.*?)(?:\|(~)?(.*?))?\]\]/mg,
  handler: function(w)
  {
    this.lookaheadRegExp.lastIndex = w.matchStart
    var lookaheadMatch = this.lookaheadRegExp.exec(w.source)
    if(lookaheadMatch && lookaheadMatch.index == w.matchStart) {
      var text = lookaheadMatch[1]
      if(lookaheadMatch[3]) { // Pretty bracketted link
        var link = lookaheadMatch[3]
        var whole = text + "|" + (lookaheadMatch[2] || "") + link
        var found_whole = store.findTarget(whole)
        var e = found_whole ?
          createTiddlyLink(w.output,whole,false,w.tiddler) :
          !lookaheadMatch[2] && isExternalLink(link) ?
            createExternalLink(w.output,link) :
            createTiddlyLink(w.output,link,false,w.tiddler)
        text = found_whole ? whole : text
      } else // Simple bracketted link
        e = createTiddlyLink(w.output,text,false,w.tiddler)
      createTiddlyText(e,text)
      w.nextMatch = this.lookaheadRegExp.lastIndex
    }
  }
},

{
  // wikiLink
  match: textPrims.unWikiLink+"?"+textPrims.wikiLink,
  handler: function(w)
  {
    if(w.matchText.substr(0,1) == textPrims.unWikiLink) {
      w.outputText(w.output,w.matchStart+1,w.nextMatch)
      return
    }
    if(w.matchStart > 0) {
      var preRegExp = new RegExp(textPrims.anyLetter,"mg")
      preRegExp.lastIndex = w.matchStart-1
      var preMatch = preRegExp.exec(w.source)
      if(preMatch.index == w.matchStart-1) {
        w.outputText(w.output,w.matchStart,w.nextMatch)
        return
      }
    }
    var link = createTiddlyLink(w.output,w.matchText,false,w.tiddler)
    w.outputText(link,w.matchStart,w.nextMatch)
  }
},

{
  // urlLink
  match: textPrims.urlPattern,
  handler: function(w)
  {
    w.outputText(createExternalLink(w.output,w.matchText),w.matchStart,w.nextMatch)
  }
},

{
  // image
  match: "\\[[<>]?[Ii][Mm][Gg]\\[",
  lookaheadRegExp: /\[([<]?)(>?)[Ii][Mm][Gg]\[([^\[\]\|]+)\](?:\[([^\]]*)\])?\]/mg,
  handler: function(w)
  {
    var lookaheadRegExp = this.lookaheadRegExp
    lookaheadRegExp.lastIndex = w.matchStart
    var lookaheadMatch = lookaheadRegExp.exec(w.source)
    if(lookaheadMatch && lookaheadMatch.index == w.matchStart) {
      var e = w.output
      if(lookaheadMatch[4]) {
        var link = lookaheadMatch[4]
        e = isExternalLink(link) ?
          createExternalLink(w.output,link) :
          createTiddlyLink(w.output,link,false,w.tiddler)
        $(e).addClass("imageLink")
      }
      var img = createTiddlyElement(e,"img")
      if(lookaheadMatch[1]) img.align = "left"
      else if(lookaheadMatch[2]) img.align = "right"
      var src = lookaheadMatch[3].split(' ')
      var where = src[0]
      // kludge for images to be visible under tinys etc
      img.src = isUrl(where) ? where : "/Users/rd/Dropbox/" + where
      if(src[1] == '' && !img.align)
        img.width = config.options.txtWidth
      else if(src[1])
        img.width = src[1]
      if(img.align) img.style = "margin-" +
        (img.align=="right" ? "left:" : "right:") + (src[2] || "10") + "px;"
      w.nextMatch = lookaheadRegExp.lastIndex
    }
  }
},

{
  // html
  match: "<[Hh][Tt][Mm][Ll]>",
  lookaheadRegExp: /<[Hh][Tt][Mm][Ll]>((?:.|\n)*?)<\/[Hh][Tt][Mm][Ll]>/mg,
  handler: function(w)
  {
    this.lookaheadRegExp.lastIndex = w.matchStart
    var lookaheadMatch = this.lookaheadRegExp.exec(w.source)
    if(lookaheadMatch && lookaheadMatch.index == w.matchStart) {
      createTiddlyElement(w.output,"span").innerHTML = lookaheadMatch[1]
      w.nextMatch = this.lookaheadRegExp.lastIndex
    }
  }
},

{
  // commentByBlock
  match: "/%",
  lookaheadRegExp: /\/%((?:.|\n)*?)%\//mg,
  handler: function(w)
  {
    this.lookaheadRegExp.lastIndex = w.matchStart
    var lookaheadMatch = this.lookaheadRegExp.exec(w.source)
    if(lookaheadMatch && lookaheadMatch.index == w.matchStart)
      w.nextMatch = this.lookaheadRegExp.lastIndex
  }
},

{
  // characterFormat
  match: "''|//|__|\\^\\^|~~|--(?!\\s|$)|\\{\\{\\{",
  handler: function(w)
  {
    switch(w.matchText) {
    case "''":
      w.subWikifyTerm(createTiddlyElement(w.output,"strong"),/('')/mg)
      break
    case "//":
      w.subWikifyTerm(createTiddlyElement(w.output,"em"),/(\/\/)/mg)
      break
    case "__":
      w.subWikifyTerm(createTiddlyElement(w.output,"u"),/(__)/mg)
      break
    case "^^":
      w.subWikifyTerm(createTiddlyElement(w.output,"sup"),/(\^\^)/mg)
      break
    case "~~":
      w.subWikifyTerm(createTiddlyElement(w.output,"sub"),/(~~)/mg)
      break
    case "--":
      w.subWikifyTerm(createTiddlyElement(w.output,"strike"),/(--)/mg)
      break
    case "{{{":
      var lookaheadRegExp = /\{\{\{((?:.|\n)*?)\}\}\}/mg
      lookaheadRegExp.lastIndex = w.matchStart
      var lookaheadMatch = lookaheadRegExp.exec(w.source)
      if(lookaheadMatch && lookaheadMatch.index == w.matchStart) {
        createTiddlyElement(w.output,"code",null,null,lookaheadMatch[1])
        w.nextMatch = lookaheadRegExp.lastIndex
      }
      break
    }
  }
},

{
  // customFormat
  match: "@@|\\{\\{",
  handler: function(w)
  {
    switch(w.matchText) {
    case "@@":
      var e = createTiddlyElement(w.output,"span")
      var styles = config.formatterHelpers.inlineCssHelper(w)
      if(styles.length == 0)
        e.className = "marked"
      else
        config.formatterHelpers.applyCssHelper(e,styles)
      w.subWikifyTerm(e,/(@@)/mg)
      break
    case "{{":
      var lookaheadRegExp = /\{\{[\s]*([\w]+[\s\w]*)[\s]*\{(\n?)/mg
      lookaheadRegExp.lastIndex = w.matchStart
      var lookaheadMatch = lookaheadRegExp.exec(w.source)
      if(lookaheadMatch) {
        w.nextMatch = lookaheadRegExp.lastIndex
        e = createTiddlyElement(w.output,lookaheadMatch[2] == "\n" ? "div" : "span",null,lookaheadMatch[1])
        w.subWikifyTerm(e,/(\}\}\})/mg)
      }
      break
    }
  }
},

{
  // mdash
  match: "--",
  handler: function(w)
  {
    createTiddlyElement(w.output,"span").innerHTML = "&mdash;"
  }
},

{
  // lineBreak
  match: "\\n|<br ?/?>",
  handler: function(w) {createTiddlyElement(w.output,"br")}
},

{
  // rawText
  match: "\"{3}|<nowiki>",
  lookaheadRegExp: /(?:\"{3}|<nowiki>)((?:.|\n)*?)(?:\"{3}|<\/nowiki>)/mg,
  handler: function(w)
  {
    this.lookaheadRegExp.lastIndex = w.matchStart
    var lookaheadMatch = this.lookaheadRegExp.exec(w.source)
    if(lookaheadMatch && lookaheadMatch.index == w.matchStart) {
      createTiddlyElement(w.output,"span",null,null,lookaheadMatch[1])
      w.nextMatch = this.lookaheadRegExp.lastIndex
    }
  }
},

{
  // htmlEntitiesEncoding
  match: "(?:(?:&#?[a-zA-Z0-9]{2,8};|.)(?:&#?(?:x0*(?:3[0-6][0-9a-fA-F]|1D[c-fC-F][0-9a-fA-F]|20[d-fD-F][0-9a-fA-F]|FE2[0-9a-fA-F])|0*(?:76[89]|7[7-9][0-9]|8[0-7][0-9]|761[6-9]|76[2-7][0-9]|84[0-3][0-9]|844[0-7]|6505[6-9]|6506[0-9]|6507[0-1]));)+|&#?[a-zA-Z0-9]{2,8};)",
  handler: function(w)
  {
    createTiddlyElement(w.output,"span").innerHTML = w.matchText
  }
}

]

//--
//-- Wikifier
//--

function Wikifier(source,formatter,highlightRegExp,tiddler)
{
  this.source = source
  this.output = null
  this.formatter = formatter
  this.nextMatch = 0
  this.highlightRegExp = highlightRegExp
  this.highlightMatch = null
  if(highlightRegExp) {
    highlightRegExp.lastIndex = 0
    this.highlightMatch = highlightRegExp.exec(source)
  }
  this.tiddler = tiddler
}

Wikifier.prototype.subWikify = function(output,terminator)
{
  if(terminator)
    this.subWikifyTerm(output,new RegExp("(" + terminator + ")","mg"))
  else
    this.subWikifyUnterm(output)
}

Wikifier.prototype.subWikifyUnterm = function(output)
{
  var oldOutput = this.output
  this.output = output
  this.formatter.formatterRegExp.lastIndex = this.nextMatch
  var formatterMatch = this.formatter.formatterRegExp.exec(this.source)
  while(formatterMatch) {
    // Output any text before the match
    if(formatterMatch.index > this.nextMatch)
      this.outputText(this.output,this.nextMatch,formatterMatch.index)
    // Set the match parameters for the handler
    this.matchStart = formatterMatch.index
    this.matchLength = formatterMatch[0].length
    this.matchText = formatterMatch[0]
    this.nextMatch = this.formatter.formatterRegExp.lastIndex
    for(var t=1; t < formatterMatch.length; t++)
      if(formatterMatch[t]) {
        this.formatter.formatters[t-1].handler(this)
        this.formatter.formatterRegExp.lastIndex = this.nextMatch
        break
      }
    formatterMatch = this.formatter.formatterRegExp.exec(this.source)
  }
  if(this.nextMatch < this.source.length) {
    this.outputText(this.output,this.nextMatch,this.source.length)
    this.nextMatch = this.source.length
  }
  this.output = oldOutput
}

Wikifier.prototype.subWikifyTerm = function(output,terminatorRegExp)
{
  var oldOutput = this.output
  this.output = output
  terminatorRegExp.lastIndex = this.nextMatch
  var terminatorMatch = terminatorRegExp.exec(this.source)
  this.formatter.formatterRegExp.lastIndex = this.nextMatch
  var formatterMatch = this.formatter.formatterRegExp.exec(terminatorMatch ? this.source.substr(0,terminatorMatch.index) : this.source)
  while(terminatorMatch || formatterMatch) {
    if(terminatorMatch && (!formatterMatch || terminatorMatch.index <= formatterMatch.index)) {
      if(terminatorMatch.index > this.nextMatch)
        this.outputText(this.output,this.nextMatch,terminatorMatch.index)
      this.matchText = terminatorMatch[1]
      this.matchLength = terminatorMatch[1].length
      this.matchStart = terminatorMatch.index
      this.nextMatch = this.matchStart + this.matchLength
      this.output = oldOutput
      return
    }
    if(formatterMatch.index > this.nextMatch)
      this.outputText(this.output,this.nextMatch,formatterMatch.index)
    this.matchStart = formatterMatch.index
    this.matchLength = formatterMatch[0].length
    this.matchText = formatterMatch[0]
    this.nextMatch = this.formatter.formatterRegExp.lastIndex
    var t
    for(t=1; t < formatterMatch.length; t++) {
      if(formatterMatch[t]) {
        this.formatter.formatters[t-1].handler(this)
        this.formatter.formatterRegExp.lastIndex = this.nextMatch
        break
      }
    }
    terminatorRegExp.lastIndex = this.nextMatch
    terminatorMatch = terminatorRegExp.exec(this.source)
    formatterMatch = this.formatter.formatterRegExp.exec(terminatorMatch ? this.source.substr(0,terminatorMatch.index) : this.source)
  }
  if(this.nextMatch < this.source.length) {
    this.outputText(this.output,this.nextMatch,this.source.length)
    this.nextMatch = this.source.length
  }
  this.output = oldOutput
}

Wikifier.prototype.outputText = function(place,startPos,endPos)
{
  if(place.className.indexOf("tiddlyLink") == -1) {
    //# Check for highlights
    while(this.highlightMatch && (this.highlightRegExp.lastIndex > startPos) && (this.highlightMatch.index < endPos) && (startPos < endPos)) {
      //# Deal with any plain text before the highlight
      if(this.highlightMatch.index > startPos) {
        createTiddlyText(place,this.source.substring(startPos,this.highlightMatch.index))
        startPos = this.highlightMatch.index
      }
      //# Deal with the highlight
      var highlightEnd = Math.min(this.highlightRegExp.lastIndex,endPos)
      var theHighlight = createTiddlyElement(place,"span",null,"highlight",this.source.substring(startPos,highlightEnd))
      startPos = highlightEnd
      //# Nudge along to the next highlight if we're done with this one
      if(startPos >= this.highlightRegExp.lastIndex)
        this.highlightMatch = this.highlightRegExp.exec(this.source)
    }
  }
  //# Do the unhighlighted text left over
  if(startPos < endPos) {
    var name = this.source.substring(startPos,endPos)
    if(/tiddlyLink/.test(place.className)) name = splitWordsIfRequired(name)
    createTiddlyText(place,name)
  }
}

function wikify(source,output,highlightRegExp,tiddler)
{
  if(source)
    new Wikifier(source,formatter,highlightRegExp,tiddler).subWikify(output)
}

function highlightify(source,output,highlightRegExp,tiddler)
{
  if(source) {
    var wikifier = new Wikifier(source,formatter,highlightRegExp,tiddler)
    wikifier.outputText(output,0,source.length)
  }
}

//--
//-- Macro definitions
//--

function invokeMacro(place,macro,params,wikifier,tiddler)
{
  try {
    var m = macros[macro]
    if(m && m.handler) {
      var elem = story.findContainingTiddler(place)
      window.tiddler = elem && store.fetchTiddler(elem.getAttribute("tiddler"))
      window.place = place
      var mParams = m.noPreParse || params.readMacroParams(false)
      m.handler(place,macro,mParams,wikifier,params,tiddler)
    } else {
      createTiddlyError(place,messages.macroError.format([macro]),
        messages.macroErrorDetails.format([macro,messages.missingMacro]))
    }
  } catch(ex) {
    createTiddlyError(place,messages.macroError.format([macro]),
      messages.macroErrorDetails.format([macro,ex.toString()]))
  }
}

function versions() {
  return {
    TiddlyWiki: "2.8.1",
    jQuery: jQuery.fn.jquery,
    hotkeys: jQuery.hotkeys.version
  }
}

macros.today.handler = function(place,macroName,params)
{
  var now = new Date()
  var text = params[0] ? now.formatString(params[0].trim()) : now.toLocaleString()
  $("<span/>").text(text).appendTo(place)
}

Date.prototype.createdCompareString = function(anchorYear,anchorMMDD)
{
  return (this.formatMMDD() != anchorMMDD ? "00" : twoPad(
    anchorYear - this.getUTCFullYear())) + this.convertToYYYYMMDDHHMM()
}

Date.prototype.formatMMDD = function() {return this.formatString("0MM0DD")}

macros.timeline = {
  handler: function(place,macroName,params,wikifier,paramString) {
    var container = $("<div />").attr("params", paramString).
      attr("macroName", macroName).appendTo(place)[0]
    this.refresh(container)
  },
  refresh: function(container) {
    $(container).attr("refresh", "macro").empty()
    var paramString = $(container).attr("params")
    var params = paramString.parseParams("anon")[0].anon || []
    var sortField = params[0] || "modified"
    var tiddlers = []
    store.forEachTiddler(function(title,tiddler) {
      if (!excludeTitle(title)) tiddlers.push(tiddler)
    })
    if(sortField == "modified") {
      tiddlers = tiddlers.sort(
        function(a,b) {return basicCompare(a.modified, b.modified)}
      )
    } else {
      tiddlers = tiddlers.sort(
        function(a,b) {return basicCompare(a.created, b.created)}
      )
      if(config.options.chkShowCreatedHistory) {
        var dayShift = parseInt(params[2] || config.options.txtCreatedShift)
        var anchorDate = new Date()
        anchorDate.setDate(anchorDate.getDate() + dayShift)
        var anchorYear = anchorDate.getUTCFullYear()
        var anchorMMDD = anchorDate.formatMMDD()
        tiddlers = tiddlers.concat(
          tiddlers.filter(t =>
            t.created.formatMMDD() == anchorMMDD &&
            t.created.getUTCFullYear() != anchorYear
          ).sort(
            function(a, b) {
              return basicCompare(
                a.created.createdCompareString(anchorYear,anchorMMDD),
                b.created.createdCompareString(anchorYear,anchorMMDD)
              )
            }
          )
        )
      }
    }
    var lastGroup = "", ul
    var lines = params[1] || config.options.txtLinesRecentChanges
    var last = tiddlers.length-Math.min(tiddlers.length,parseInt(lines))
    for(var t=tiddlers.length-1; t>=last; t--) {
      var tiddler = tiddlers[t]
      var group = tiddler[sortField].formatString('DD MMM YYYY')
      if(typeof(ul) == "undefined" || group != lastGroup) {
        ul = document.createElement("ul")
        $(ul).addClass("timeline")
        container.appendChild(ul)
        createTiddlyElement(ul,"li",null,"listTitle",group)
        lastGroup = group
      }
      var item = createTiddlyElement(ul,"li",null,"listLink")
      wikify("<<view title link>>",item,null,tiddler)
    }
  },
}

macros.permaview.handler = function(place)
{
  createTiddlyButton(place,this.label,this.tooltip,this.onClick)
}

macros.permaview.onClick = function(e)
{
  story.permaView()
}

macros.message.handler = function(place,macroName,params)
{
  if(params[0]) {
    var names = params[0].split(".")
    var lookupMessage = function(root,nameIndex) {
        if(root[names[nameIndex]]) {
          if(nameIndex < names.length-1)
            return (lookupMessage(root[names[nameIndex]],nameIndex+1))
          else
            return root[names[nameIndex]]
        } else
          return null
      }
    var m = lookupMessage(config,0)
    if(m == null)
      m = lookupMessage(window,0)
    createTiddlyText(place,m.toString().format(params.splice(1)))
  }
}

macros.view.depth = 0
macros.view.values = []
macros.view.views = {
  text: function(value,place,params,wikifier,paramString,tiddler) {
    // only used for tiddler title
    highlightify(splitWordsIfRequired(value),place,searchRegex,tiddler)
  },
  link: function(value,place,params,wikifier,paramString,tiddler) {
    createTiddlyLink(place,value,true)
  },
  wikified: function(value,place,params,wikifier,paramString,tiddler) {
    var values = macros.view.values
    var depth = macros.view.depth
    if(depth > 50 || depth > 0 && value == values[depth-1]) return
    values[depth] = value
    macros.view.depth++
    if(params[2]) value=params[2].unescapeLineBreaks().format([value])
    wikify(value,place,searchRegex,tiddler)
    macros.view.depth--
    values[macros.view.depth] = null
  },
  date: function(value,place,params,wikifier,paramString,tiddler) {
    value = Date.convertFromYYYYMMDDHHMM(value)
    createTiddlyText(place,value.formatString(params[2] || "DD MMM YYYY"))
  }
}

macros.view.handler = function(place,macroName,params,wikifier,paramString,tiddler)
{
  if((tiddler instanceof Tiddler) && params[0]) {
    var value = store.getValue(tiddler,params[0])
    if(value) {
      var type = params[1] || macros.view.defaultView
      var handler = macros.view.views[type]
      if(handler) handler(value,place,params,wikifier,paramString,tiddler)
    }
  }
}

macros.edit.handler = function(place,macroName,params,wikifier,paramString,tiddler)
{
  var field = params[0]
  var rows = params[1] || 0
  var defVal = params[2] || ''
  if((tiddler instanceof Tiddler) && field) {
    if(field != "text" && !rows) {
      var e = createTiddlyElement(null,"input",null,null,null,
        {type: "text", edit: field, size: "40"})
      e.value = store.getValue(tiddler,field) || defVal
      place.appendChild(e)
    } else {
      var wrapper1 = createTiddlyElement(null,"fieldset",null,"fieldsetFix")
      var wrapper2 = createTiddlyElement(wrapper1,"div")
      e = createTiddlyElement(wrapper2,"textarea")
      var v = e.value = store.getValue(tiddler,field) || defVal
      rows = rows || 10
      var lines = v.match(/\n/mg)
      var maxLines = Math.max(parseInt(config.options.txtMaxEditRows),5)
      if(lines != null && lines.length > rows) rows = lines.length + 5
      rows = Math.min(rows,maxLines)
      e.setAttribute("rows",rows)
      e.setAttribute("edit",field)
      place.appendChild(wrapper1)
    }
    return e
  }
}

macros.newTiddler.handler = function(place)
{
  createTiddlyButton(place,"new tiddler","Create a new tiddler",this.onClick)
}

macros.newTiddler.onClick = function(event)
{
  if(event.shiftKey) {
    seed()
    return
  }
  var title = "NewTiddler"
  story.displayTiddler(null,title,2)
  story.focusTiddler(title)
}

macros.search.handler = function(place)
{
  createTiddlyButton(place,"search","Search all tiddlers",this.onClick)
  var textBox =
    createTiddlyElement(null,"input",null,"txtOptionInput searchField")
  if(config.isSafari) {
    textBox.setAttribute("type","search")
    textBox.setAttribute("results","15")
  } else
    textBox.setAttribute("type","text")
  place.appendChild(textBox)
  textBox.onkeyup = this.onKeyPress
  textBox.onfocus = this.select
}

macros.search.onClick = function(e)
{
  var text = this.nextSibling.value
  doSearch(
    config.options.chkRegExp || e.altKey ? text : text.toLowerCase(), 
    null, 
    e.altKey
  )
}

macros.search.onKeyPress = function(e)
{
  switch(e.keyCode) {
    case 9: // Tab
      return
    case 13: // Return
      doSearch(this.value)
      break
    case 27: // Escape
      this.value = ""
      clearMessage()
  }
}

macros.tabs.handler = function(place,macroName,params)
{
  var cookie = params[0]
  var numTabs = (params.length-1)/3
  var wrapper = createTiddlyElement(null,"div",null,"tabsetWrapper " + cookie)
  var tabset = createTiddlyElement(wrapper,"div",null,"tabset")
  tabset.setAttribute("cookie",cookie)
  var validTab = false
  var t
  for(t=0; t < numTabs; t++) {
    var label = params[t*3+1]
    var tooltip = params[t*3+2]
    var content = params[t*3+3]
    var accessKey = content == "OpenTiddlers" ? "O" :
      content == "RecentChanges" ? "R" : null
    var tab = createTiddlyButton(tabset,label,tooltip,this.onClickTab,
      "tab tabUnselected",null,accessKey)
    createTiddlyElement(tab,"span",null,null," ",
      {style:"font-size:0pt;line-height:0px"})
    tab.setAttribute("tab",label)
    tab.setAttribute("content",content)
    tab.title = tooltip
    if(config.options[cookie] == label) validTab = true
  }
  if(!validTab) config.options[cookie] = params[1]
  place.appendChild(wrapper)
  this.switchTab(tabset,config.options[cookie])
}


macros.tabs.onClickTab = function(e)
{
  macros.tabs.switchTab(this.parentNode,this.getAttribute("tab"))
}

macros.tabs.switchTab = function(tabset,tab)
{
  var nodes = tabset.childNodes
  var theTab = null
  for(var t=0; t < nodes.length; t++) {
    var selected = nodes[t].getAttribute("tab") == tab
    nodes[t].className = selected ? "tab tabSelected" : "tab tabUnselected"
    if(selected) theTab = nodes[t]
  }
  if(theTab) {
    if(tabset.nextSibling && tabset.nextSibling.className == "tabContents")
      $(tabset.nextSibling).remove()
    var tabContent = createTiddlyElement(null,"div",null,"tabContents")
    tabset.parentNode.insertBefore(tabContent,tabset.nextSibling)
    var contentTitle = theTab.getAttribute("content")
    wikify(store.getTiddlerText(contentTitle),tabContent,null,
      store.fetchTiddler(contentTitle))
  }
}

tiddler_ = function(count) {
  return "%0 tiddler%1".format([count || 'No', count == 1 ? '' : 's'])
}

jsonChanges = function(full) {
  var uc = macros.unsavedChanges
  var names = Array.from(full ? uc.full : uc.medited)
  var tiddlers = names.map(function(name) {
    t = store.fetchTiddler(name)
    if(!t) return name
    t = Object.assign({}, t)
    delete t.links
    delete t.linksUpdated
    return t
  })
  return JSON.stringify(tiddlers)
}

ajaxChangeTiddler = function(title, action, unshared) {
  ajaxPost('change_tiddler', {
      type: wikiType(),
      title: title,
      action: action,
      shared: unshared ? "false" : "true",
      changes: jsonChanges(),
    },
    function success(text) {_dump(text)},
    function fail(data, status) {_dump('ruby change_tiddler failed for ' + title)}
  )
}

// Eric Shulman, heavily bowdlerized by Richard Drake
macros.unsavedChanges = {
  handler: function(place) {
    this.render(createTiddlyElement(place,"span",null,"unsavedChanges"))
  },
  render: function(place) {
    $(place).empty()
    var count = this.changed.size
    var label = "save changes to " + tiddler_(count)
    if (count) createTiddlyButton(place,label,"Save all changes",saveChanges)
  },
  refresh: function() {
    $(".unsavedChanges").get().forEach(span => this.render(span))
  },
  addChange: function(title, excluded) {
    this.changed.delete(title)
    if (!excluded) this.changed.add(title)
    if(!excluded || excluded == "medited") {
      this.medited.delete(title)
      this.medited.add(title)
    }
    this.full.delete(title)
    this.full.add(title)
  },
  reset: function() {
    this.changed = new Set
    this.medited = new Set
    this.full = new Set
  },
}

//--
//-- Tiddler toolbar
//--

// Create a toolbar command button
macros.toolbar.createCommand = function(place,commandName,tiddler,className,command)
{
  var cmd = command.type == "popup" ? this.onClickPopup : this.onClickCommand
  var btn = createTiddlyButton(null,command.text,command.tooltip,cmd)
  btn.setAttribute("commandName",commandName)
  btn.setAttribute("tiddler",tiddler.title)
  $(btn).addClass("command_" + commandName)
  if(className) $(btn).addClass(className)
  place.appendChild(btn)
}

macros.toolbar.onClickCommand = function(e)
{
  e.cancelBubble = true
  e.stopPropagation()
  var command = commands[this.getAttribute("commandName")]
  return command.handler(e,this,this.getAttribute("tiddler"))
}

macros.toolbar.onClickPopup = function(e)
{
  e.cancelBubble = true
  e.stopPropagation()
  var popup = Popup.create(this)
  var command = commands[this.getAttribute("commandName")]
  var title = this.getAttribute("tiddler")
  popup.setAttribute("tiddler",title)
  command.handlePopup(popup,title,e.altKey)
  Popup.show()
}

// Invoke the first command encountered from a given place that is tagged with a specified class
macros.toolbar.invokeCommand = function(place,className,event)
{
  var children = place.getElementsByTagName("a")
  for(var t=0; t < children.length; t++) {
    var c = children[t]
    if($(c).hasClass(className) && c.getAttribute && c.getAttribute("commandName")) {
      if(c.onclick instanceof Function) c.onclick.call(c,event)
      break
    }
  }
}

macros.toolbar.handler = function(place,macroName,params,wikifier,paramString,tiddler)
{
  for(var t=0; t < params.length; t++) {
    var c = params[t]
    var i = "+-".indexOf(c.substr(0,1)) + 1
    if(i) c = c.substr(1)
    var className = ["","defaultCommand","cancelCommand"][i]
    var command = commands[c]
    if(command) this.createCommand(place,c,tiddler,className,command)
  }
}

//--
//-- Menu and toolbar commands
//--

checkChanges = function(title) {
  return !story.hasChanges(title) || confirm(
    "Are you sure you want to abandon your changes to " + title + "?")
}

commands.closeTiddler.handler = function(event,src,title)
{
  if(checkChanges(title)) story.closeTiddler(title,true)
}

commands.cancelTiddler.handler = function(event,src,title)
{
  if(checkChanges(title)) story.displayTiddler(null,title,1)
}

commands.editTiddler.handler = function(event,src,title)
{
  clearMessage()
  var elem = story.getTiddler(title)
  story.displayTiddler(null,title,2)
  var e = story.getTiddlerField(title,"text")
  if(e) setCaretPosition(e,0)
}

commands.saveTiddler.handler = function(event,src,title)
{
  var newTitle = story.saveTiddler(title)
  if(newTitle) story.displayTiddler(null,newTitle,1)
}

commands.deleteTiddler.handler = function(event,src,title)
{
  tiddler = store.fetchTiddler(title)
  if(!tiddler || excludeTitle(title))
    story.closeTiddler(title,true)
  else if(confirm(this.warning.format([title]))) {
    store.removeTiddler(title)
    cacheTiddlerSplits()
    story.closeTiddler(title,true)
  }
}

commands.references.handlePopup = function(popup,title,altKey)
{
  var references = store.getReferringTiddlers(title,altKey)
  var size = references.length
  if (size) {
    if (size > 10)
      createTiddlyElement(popup,"li",null,"disabled", size + " references")
    for(var r=0; r < references.length; r++) {
      var place = createTiddlyElement(popup,"li")
      createTiddlyLink(place,references[r].title,true,null,true)
    }
  }
  else
    createTiddlyElement(popup,"li",null,"disabled","No references")
}

//--
//-- Tiddler() object
//--

function Tiddler(title)
{
  this.title = title
  this.text = ""
  this.creator = null
  this.modifier = null
  this.created = new Date()
  this.modified = this.created
  this.links = []
  this.linksUpdated = false
  this.fields = {}
  return this
}

// Increment the changeCount of a tiddler
Tiddler.prototype.incChangeCount = function()
{
  var c = this.fields['changecount']
  c = c ? parseInt(c) : 0
  this.fields['changecount'] = String(c+1)
}

// Change the text and other attributes of a tiddler
Tiddler.prototype.set = function(title,text,modified,modifier,created,creator,fields)
{
  this.assign(title,text,modified,modifier,created,creator,fields)
  this.changed()
}

// Change the text and other attributes of a tiddler without triggered a tiddler.changed() call
Tiddler.prototype.assign = function(title,text,modified,modifier,created,creator,fields)
{
  if(title != undefined) this.title = title
  if(text != undefined) this.text = text
  if(modified != undefined) this.modified = modified
  if(modifier != undefined) this.modifier = modifier
  if(created != undefined) this.created = created
  if(creator != undefined) this.creator = creator
  if(fields != undefined) this.fields = fields
}

// Static method to convert "\n" to newlines, "\s" to "\"
Tiddler.unescapeLineBreaks = function(text)
{
  return text ? text.unescapeLineBreaks() : ""
}

// Convert newlines to "\n", "\" to "\s"
Tiddler.prototype.escapeLineBreaks = function()
{
  return this.text.escapeLineBreaks()
}

// Updates the secondary information (like links array) after a change to a tiddler
Tiddler.prototype.changed = function() {
  this.links = []
  var text = this.text
  // remove 'quoted' text before scanning tiddler source
  text = text.replace(/\/%((?:.|\n)*?)%\//g,"").
    replace(/\{{3}((?:.|\n)*?)\}{3}/g,"").
    replace(/"""((?:.|\n)*?)"""/g,"").
    replace(/<nowiki\>((?:.|\n)*?)<\/nowiki\>/g,"").
    replace(/<html\>((?:.|\n)*?)<\/html\>/g,"").
    replace(/<script((?:.|\n)*?)<\/script\>/g,"")
  var tiddlerLinkRegExp = textPrims.tiddlerAnyLinkRegExp
  var formatMatch = tiddlerLinkRegExp.exec(text)
  while(formatMatch) {
    var lastIndex = tiddlerLinkRegExp.lastIndex
    if(formatMatch[1]) {
      // wikiWordLink
      if(formatMatch.index > 0) {
        var preRegExp = new RegExp(textPrims.unWikiLink+"|"+textPrims.anyLetter,"mg")
        preRegExp.lastIndex = formatMatch.index-1
        var preMatch = preRegExp.exec(text)
        if(preMatch.index != formatMatch.index-1)
          this.links.pushUnique(formatMatch[1])
      } else {
        this.links.pushUnique(formatMatch[1])
      }
    }
    else if(formatMatch[2] && !isExternalLink(formatMatch[3])) // titledBrackettedLink
      this.links.pushUnique(formatMatch[3])
    else if(formatMatch[4]) // brackettedLink
      this.links.pushUnique(formatMatch[4])
    tiddlerLinkRegExp.lastIndex = lastIndex
    formatMatch = tiddlerLinkRegExp.exec(text)
  }
  this.linksUpdated = true
  this.getSplitName()
}

Tiddler.prototype.getSubtitle = function()
{
  var modified = this.modified
  modified = modified ? modified.formatString('DD mmm YY 0hh:0mm') : "(unknown)"
  return "%0 - %1".format([this.title,modified])
}

//--
//-- TiddlyWiki instance contains Tiddlers
//--

function TiddlyWiki()
{
  var tiddlers = {} // Hashmap by name
  this.tiddlersUpdated = false
  this.slices = {} // map tiddlerName->(map sliceName->sliceValue). Lazy.
  this.fetchTiddler = function(title) {
    return tiddlers[title]
  }
  this.deleteTiddler = function(title) {
    delete this.slices[title]
    delete tiddlers[title]
  }
  this.addTiddler = function(tiddler) {
    delete this.slices[tiddler.title]
    tiddlers[tiddler.title] = tiddler
  }
  this.forEachTiddler = function(callback) {
    for(var t in tiddlers) callback.call(this,t,tiddlers[t])
  }
}

TiddlyWiki.prototype.setDirty = function(dirty)
{
  var clearUnsaved = this.dirty && !dirty
  this.dirty = dirty
  if (clearUnsaved) {
    macros.unsavedChanges.reset()
    macros.unsavedChanges.refresh()
  }
}

TiddlyWiki.prototype.isDirty = function()
{
  return this.dirty
}

TiddlyWiki.prototype.tiddlerExists = function(title)
{
  return !!this.fetchTiddler(title)
}

TiddlyWiki.prototype.isShadowTiddler = function(title)
{
  return config.shadowTiddlers.hasOwnProperty(title)
}

TiddlyWiki.prototype.isAvailable = function(title) {
  return this.tiddlerExists(title) || this.isShadowTiddler(title)
}

TiddlyWiki.prototype.getTiddlerText = function(title)
{
  if(!title) return ""
  pos = title.indexOf("::")
  if(pos != -1) {
    var slice = this.getTiddlerSlice(title.substr(0,pos),title.substr(pos + 2))
    if(slice) return slice
  }
  var tiddler = this.fetchTiddler(title)
  return tiddler ? tiddler.text :
    this.isShadowTiddler(title) ? config.shadowTiddlers[title] : ""
}

TiddlyWiki.prototype.getRecursiveTiddlerText = function(title,depth)
{
  var bracketRegExp = new RegExp("(?:\\[\\[([^\\]]+)\\]\\])","mg")
  var text = this.getTiddlerText(title)
  var textOut = []
  var match,lastPos = 0
  do {
    match = bracketRegExp.exec(text)
    if(match) {
      textOut.push(text.substr(lastPos,match.index-lastPos))
      if(match[1]) {
        if(depth <= 0)
          textOut.push(match[1])
        else
          textOut.push(this.getRecursiveTiddlerText(match[1],depth-1))
      }
      lastPos = match.index + match[0].length
    } else {
      textOut.push(text.substr(lastPos))
    }
  } while(match)
  return textOut.join("")
}

TiddlyWiki.prototype.slicesRE = /(?:^([\'\/]{0,2})~?([\.\w]+)\:\1[\t\x20]*([^\n]*)[\t\x20]*$)|(?:^\|([\'\/]{0,2})~?([\.\w]+)\:?\4\|[\t\x20]*([^\|\n]*)[\t\x20]*\|$)/gm
// @internal
TiddlyWiki.prototype.calcAllSlices = function(title)
{
  var slices = {}
  var text = this.getTiddlerText(title)
  this.slicesRE.lastIndex = 0
  var m = this.slicesRE.exec(text)
  while(m) {
    if(m[2])
      slices[m[2]] = m[3]
    else
      slices[m[5]] = m[6]
    m = this.slicesRE.exec(text)
  }
  return slices
}

// Returns the slice of text of the given name
TiddlyWiki.prototype.getTiddlerSlice = function(title,sliceName)
{
  var slices = this.slices[title]
  if(!slices) {
    slices = this.calcAllSlices(title)
    this.slices[title] = slices
  }
  return slices[sliceName]
}

TiddlyWiki.prototype.notify = function(title)
{
  config.notifiers.forEach(n => n.name == title && n.notify(title))
  refreshDisplay(title)
}

TiddlyWiki.prototype.removeTiddler = function(title, unshared)
{
  if(this.tiddlerExists(title)) {
    macros.unsavedChanges.addChange(title, false)
    this.deleteTiddler(title)
    ajaxChangeTiddler(title, "deleted", unshared)
    this.notify(title)
    this.setDirty(true)
    macros.unsavedChanges.refresh()
  }
}

excludeTitle = function(title) {
  return title == "Search" || title == "DefaultTiddlers"
}

TiddlyWiki.prototype.saveTiddler = function(title,newTitle,newBody,modifier,
  modified,fields,created,creator,unshared,medit)
{
  if (title != newTitle) {
    macros.unsavedChanges.addChange(title, true)
    var exclude = false
  } else exclude = excludeTitle(title)
  macros.unsavedChanges.addChange(newTitle, exclude || medit && "medited")
  var tiddler = this.fetchTiddler(title)
  if(tiddler) {
    created = created || tiddler.created // preserve created date
    creator = creator || tiddler.creator
    this.deleteTiddler(title)
  } else {
    created = created || modified
    tiddler = new Tiddler()
  }
  tiddler.set(newTitle,newBody,modified,modifier,created,creator,fields)
  this.addTiddler(tiddler)
  tiddler.incChangeCount()
  if(!exclude) ajaxChangeTiddler(newTitle, "changed", unshared)
  if(title != newTitle) this.notify(title)
  this.notify(newTitle)
  if(!exclude) this.setDirty(true)
  if(this.isDirty()) macros.unsavedChanges.refresh()
  return tiddler
}

TiddlyWiki.prototype.loadFromDiv = function(src)
{
  document.getElementById(src).childNodes.forEach(node => {
    if(node.getAttribute) { // this test is needed
      var title = node.getAttribute("title")
      var tiddler = new Tiddler(title)
      this.addTiddler(tiddler)
      internalizeTiddler(tiddler,title,node)
    }
  })
  this.setDirty(false)
}

internalizeTiddler = function(tiddler,title,node)
{
  var e = node.firstChild
  while(e.nodeName!="PRE" && e.nodeName!="pre") e = e.nextSibling
  var text = e.innerHTML.replace(/\r/mg,"").htmlDecode()
  var creator = node.getAttribute("creator")
  var modifier = node.getAttribute("modifier")
  var c = node.getAttribute("created")
  var m = node.getAttribute("modified") // eg 202011150246
  var created = c ? Date.convertFromYYYYMMDDHHMM(c) : version.date
  var modified = m ? Date.convertFromYYYYMMDDHHMM(m) : created
  var fields = {}
  var attrs = node.attributes
  for(var i = attrs.length-1; i >= 0; i--) {
    var name = attrs[i].name
    if(name == "splitname" || name == "changecount" || name == "medited")
      fields[name] = attrs[i].value
  }
  tiddler.assign(title,text,modified,modifier,created,creator,fields)
}

TiddlyWiki.prototype.updateTiddlers = function()
{
  this.tiddlersUpdated = true
  this.forEachTiddler(function(title,tiddler) {tiddler.changed()})
}

TiddlyWiki.prototype.search = function(regExp) {
  var titles = [], texts = []
  this.forEachTiddler(function(title,tiddler) {
    if (!excludeTitle(title))
      if(regExp.test(title) || regExp.test(tiddler.getSplitName()))
        titles.push(tiddler)
      else if(!config.options.chkTitleOnly &&
        regExp.test(tiddler.text))
        texts.push(tiddler)
  })
  titles.sort(basicSplitCompare)
  texts.sort(basicSplitCompare)
  return titles.concat(texts)
}

TiddlyWiki.prototype.getReferringTiddlers = function(name, want_bch)
{
  // implications are that some non-existing tiddlers may show a reference that
  // really links to an existing one. As it's hard to open such a non-existing
  // tiddler, don't see this as a problem.
  if(!this.tiddlersUpdated) this.updateTiddlers()
  var results = []
  var altName = name.basicSplit()
  if (name != altName && store.fetchTiddler(altName)) altName = null
  this.forEachTiddler(function(title,tiddler) {
    var bch = title.slice(-3) == "Bch"
    var wanted = (want_bch && bch) || (!want_bch && !bch)
    if(wanted && title != name && !excludeTitle(title)) {
      var links = tiddler.links
      for(var i=0; i < links.length; i++) {
        var link = links[i]
        if(link == name ||
          (altName && link.toLowerCase()==altName && !store.fetchTiddler(link)))
        {
          results.push(tiddler)
          break
        }
      }
    }
  })
  return results.sort(basicSplitCompare)
}

TiddlyWiki.prototype.getValue = function(tiddler,name)
{
  var t = (typeof tiddler == "string") ? this.fetchTiddler(tiddler) : tiddler
  if(!t) return undefined
  var value = t[name]
  return name == "modified" || name == "created" ?
     value.convertToYYYYMMDDHHMM() :
     value || t.fields[name]
}

//--
//-- Story functions
//--

function Story(containerId,idPrefix)
{
  this.container = containerId
  this.idPrefix = idPrefix
  this.highlightRegExp = null
  this.tiddlerId = function(title) {
    title = title.replace(/_/g, "__").replace(/ /g, "_")
    var id = this.idPrefix + title
    return id==this.container ? this.idPrefix + "_" + title : id
  }
  this.containerId = function() {
    return this.container
  }
}

Story.prototype.getTiddler = function(title)
{
  return document.getElementById(this.tiddlerId(title))
}

Story.prototype.getContainer = function()
{
  return document.getElementById(this.containerId())
}

Story.prototype.forEachTiddler = function(fn)
{
  var e = this.getContainer().firstChild
  while(e) {
    var n = e.nextSibling
    var title = e.getAttribute("tiddler")
    if(title) fn.call(this,title,e)
    e = n
  }
}

Story.prototype.displayTiddlers = function(src,titles)
{
  for(var t = titles.length-1; t >= 0; t--) this.displayTiddler(src,titles[t])
}

Story.prototype.displayTiddler = function(srcElem,title,template)
{
  var elem = this.getTiddler(title)
  if(elem && (!srcElem || template == 2))
    this.refreshTiddler(title,template,srcElem==null)
  else {
    var place = this.getContainer()
    var srcTiddler = this.findContainingTiddler(srcElem)
    var before = srcTiddler ?
      srcElem.getAttribute('referer') ? srcTiddler : srcTiddler.nextSibling :
      place.firstChild
    if(!before || before != elem) {
      if(elem)
        place.insertBefore(elem,before)
      else
        elem = this.createTiddler(place,before,title,template)
      macros.openTiddlers.refreshList()
    }
  }
  if(srcElem) scrollTo(0,ensureVisible(elem))
}

Story.prototype.createTiddler = function(place,before,title,template)
{
  var elem = createTiddlyElement(null,"div",this.tiddlerId(title),"tiddler")
  elem.setAttribute("refresh","tiddler")
  place.insertBefore(elem,before)
  this.refreshTiddler(title,template,false)
  return elem
}

Story.prototype.refreshTiddler = function(title,n,force)
{
  var elem = this.getTiddler(title)
  if(elem) {
    if(this.hasChanges(title) && !force) return elem
    var currTemplate = elem.getAttribute("template")
    var template = n ?
      ["ViewTemplate", "EditTemplate"][n-1] : currTemplate || "ViewTemplate"
    if((template != currTemplate) || force) {
      var tiddler = store.fetchTiddler(title)
      if(!tiddler) {
        tiddler = new Tiddler()
        if(store.isShadowTiddler(title))
          tiddler.set(title,store.getTiddlerText(title),version.date,
            "(built-in shadow tiddler)",version.date)
        else {
          var text = title == "NewTiddler" ?
            openTiddlersRaw() :
            (template == "EditTemplate" ? "Try googling for %0" :
              "Try googling for %0. Double-click to create the tiddler.").
                format([googleWords(title)])
          tiddler.set(title,text,version.date,"(missing)",version.date)
        }
      }
      elem.setAttribute("tiddler",title)
      elem.setAttribute("template",template)
      elem.onmouseover = this.onTiddlerMouseOver
      elem.onmouseout = this.onTiddlerMouseOut
      elem.ondblclick = this.onTiddlerDblClick
      elem.onkeydown = this.onTiddlerKeyDown
      elem.innerHTML = store.getRecursiveTiddlerText(template,10)
      applyHtmlMacros(elem,tiddler)
      $(elem).toggleClass("missing",!store.tiddlerExists(title))
    }
    makeCopyable($(elem).children(".title"))
  }
}

Story.prototype.refreshAllTiddlers = function()
{
  this.forEachTiddler(function(title) {
    if(!this.hasChanges(title)) this.refreshTiddler(title,null,true)
  })
}

Story.prototype.onTiddlerMouseOver = function(e)
{
  $(this).addClass("selected")
}

Story.prototype.onTiddlerMouseOut = function(e)
{
  $(this).removeClass("selected")
}

Story.prototype.onTiddlerDblClick = function(e)
{
  var target = resolveTarget(e)
  if(target && target.nodeName.toLowerCase() != "input" &&
      target.nodeName.toLowerCase() != "textarea") {
    if(document.selection && document.selection.empty)
      document.selection.empty()
    macros.toolbar.invokeCommand(this,"defaultCommand",e)
    e.cancelBubble = true
    e.stopPropagation()
  }
}

Story.prototype.onTiddlerKeyDown = function(e)
{
  clearMessage()
  var consume = false
  switch(e.keyCode) {
    case 13: // Ctrl-Enter
      if(e.ctrlKey) {
        blurElement(this)
        macros.toolbar.invokeCommand(this,"defaultCommand",e)
        consume = true
      }
      break
    case 27: // Escape
      blurElement(this)
      macros.toolbar.invokeCommand(this,"cancelCommand",e)
      consume = true
      break
  }
  e.cancelBubble = consume
  if(consume) e.stopPropagation()
  else if(e.ctrlKey && e.key == "f") findSelection(this.getAttribute("tiddler"))
}

Story.prototype.getTiddlerField = function(title,field)
{
  var elem = this.getTiddler(title), e = null
  if(elem) {
    var children = elem.getElementsByTagName("*")
    for(var t=0; t < children.length; t++) {
      var c = children[t], type = c.tagName.toLowerCase()
      if(type == "input" || type == "textarea" &&
        (!e || c.getAttribute("edit") == field)) e = c
    }
  }
  return e
}

Story.prototype.focusTiddler = function(title)
{
  var e = this.getTiddlerField(title,"title")
  if(e) {
    e.focus()
    e.select()
  }
}

Story.prototype.closeTiddler = function(title,force)
{
  var elem = this.getTiddler(title)
  if(elem)
    if(force || !this.hasChanges(title) || title == "Search") {
      clearMessage()
      elem.id = null
      $(elem).remove()
      if(title == "Search") {
        searchText = null
        searchRegex = null
        linkTarget = null
        this.refreshAllTiddlers()
      }
      macros.openTiddlers.refreshList()
    } else
      dumpM(title + " being edited")
}

Story.prototype.hasAnyChanges = function()
{
  var changed = false
  this.forEachTiddler(function(title) {
    changed = changed || this.hasChanges(title)
  })
  return changed
}

Story.prototype.isEmpty = function()
{
  var place = this.getContainer()
  return place && place.firstChild == null
}

unWord = "[^" + textPrims.anyLetter.slice(1)

String.prototype.searchRegExp = function() {
  var s = "\\^$*+?()=!|{}[]."
  var c = this
  for(var t=0; t < s.length; t++)
    c = c.replace(new RegExp("\\" + s.substr(t,1),"g"),"\\" + s.substr(t,1))
  c = c.replace(new RegExp("^\\,"),"(^|" + unWord + ")")
  return c.replace(new RegExp("\\,$"),"(" + unWord + "|$)")
}

function showSearch(text, tiddlers, title, useRegExp, caseSensitive, smart) {
  story.refreshAllTiddlers() // update highlighting within story tiddlers
  var count = tiddlers.length
  var p = '"""', q = useRegExp ? "/" : "", r = "''"
  var s = smart ? "linkable " : ""
  var msg = r + tiddler_(count) + " matching " + s + p + q + text + q + p +
    (config.options.chkTitleOnly ? " in title" : "") +
    (caseSensitive ? " (CASE SENSITIVE)" : "") + r
  if (!useRegExp) {
    var names = queryNames()
    var punctuation = names.name.match(
      new RegExp("[^ " + textPrims.anyLetter.slice(1), "g"))
    msg += names.name.length > 50 || punctuation && punctuation.length > 2 ?
      " -- possible link: " + asTiddlyLink(names.name) :
      names.justOne ?
        " -- possible link: " + asTiddlyLink(names.minimalName) :
        " -- possible links: " + asTiddlyLink(names.minimalName) +
                          ", " + asTiddlyLink(names.name)
  }
  for(var i = 0; i < count; i++) msg += "\n" + asTiddlyLink(tiddlers[i].title)
  store.saveTiddler("Search","Search",msg,"SearchGuy",new Date(),{})
  if(title) story.moveToTop(title)
  story.displayTiddler(null,"Search")
  story.moveToTop("Search")
}

Story.prototype.search = function(text, title, smart) {
  if(!text) return
  var useRegExp = config.options.chkRegExp
  var caseSensitive = config.options.chkCaseSensitive ||
    (!useRegExp && text.match(textPrims.upperLetter))
  searchText = text
  searchRegex = new RegExp(
    useRegExp ? text : text.searchRegExp(),
    caseSensitive ? "mg" : "mig")
  linkTarget = null
  if(smart)
    ajaxPost('search', {
      type: wikiType(),
      edition: edition,
      name: queryNames().name,
      regex: searchRegex,
      case: caseSensitive,
      changes: jsonChanges(),
    },
    function success(response) {
      var json = JSON.parse(response)
      var clash = json.clash
      if(clash) {
        _dump("clash between browser edition " + edition + " and " + clash)
        displayMessage("edition clash")
      } else {
        var tiddlers = json.titles.map(t => store.fetchTiddler(t))
        tiddlers.sort(basicSplitCompare) // needed?
        showSearch(text, tiddlers, null, useRegExp, caseSensitive, true)
      }
    },
    function fail(data, status) {
      dumpM('search failed in ruby')
    })
  else {
    var tiddlers = store.search(searchRegex)
    showSearch(text, tiddlers, title, useRegExp, caseSensitive)
  }
}

Story.prototype.findContainingTiddler = function(e)
{
  while(e && !$(e).hasClass("tiddler")) {
    e = $(e).hasClass("popup") && Popup.stack[0] ? Popup.stack[0].root : e.parentNode
  }
  return e
}

Story.prototype.gatherSaveFields = function(element,fields)
{
  // based on DevTools, only adds splitname, title and text to fields
  if(element && element.getAttribute) {
    var f = element.getAttribute("edit")
    if(f) fields[f] = element.value.replace(/\r/mg,"")
    if(element.hasChildNodes()) {
      var c = element.childNodes
      for(var t=0; t < c.length; t++) this.gatherSaveFields(c[t],fields)
    }
  }
}

Story.prototype.fieldsForSave = function(tiddler)
{
  var fields = {}
  this.gatherSaveFields(tiddler,fields)
  if(fields.splitname && !fields.title)
    fields.title = fields.splitname.wikiWordize() || fields.splitname
  return fields
}

Story.prototype.hasChanges = function(title)
{
  var tiddler = this.getTiddler(title)
  if(tiddler) {
    var fields = this.fieldsForSave(tiddler)
    if(store.fetchTiddler(title)) {
      for(var n in fields) if(store.getValue(title,n) != fields[n]) return true
    } else
      if(store.isShadowTiddler(title) &&
        config.shadowTiddlers[title] == fields.text)
        // not checking for title
        return false
      else
        if(fields.text) return true // changed shadow or new tiddler
        // otherwise it's not been opened for editing, so it's unchanged
  }
  return false
}

Story.prototype.saveTiddler = function(title)
{
  var tiddler = this.getTiddler(title)
  if(tiddler) {
    var fields = this.fieldsForSave(tiddler)
    var newTitle = fields.title || title
    if(!store.tiddlerExists(newTitle)) {
      newTitle = newTitle.trim()
      var creator = "CreatorFromDec18"
    }
    if(store.tiddlerExists(newTitle) && newTitle != title) {
      if(!confirm(messages.overwriteWarning.format([newTitle]))) return null
      title = newTitle
    }
    var titleChanged = newTitle != title
    if(titleChanged) this.closeTiddler(newTitle,true)
    tiddler.id = this.tiddlerId(newTitle)
    tiddler.setAttribute("tiddler",newTitle)
    tiddler.setAttribute("template",1)
    if(store.tiddlerExists(title)) {
      var t = store.fetchTiddler(title)
      var extendedFields = t.fields
      creator = t.creator
      var splitChanged = !titleChanged && fields.splitname != extendedFields.splitname
    } else {
      extendedFields = {}
      titleChanged = true
    }
    extendedFields.splitname = fields.splitname
    var text = fields.text.replace(/ +\n/g, "\n").replace(/\s+$/, "")
    store.saveTiddler(title,newTitle,text,"FromDec18",new Date(),
      extendedFields,null,creator)
    if(titleChanged || splitChanged) {
      cacheTiddlerSplits()
      refreshDisplay() // links in MainMenu
      this.refreshAllTiddlers() // links in the text of open tiddlers
    }
    return newTitle
  }
  return null
}

Story.prototype.permaView = function()
{
  var links = []
  this.forEachTiddler(function(title) {links.push(title)})
  location.hash = encodeURIComponent(links.join(" ")) || "#"
}

//--
//-- Refresh mechanism
//--

config.notifiers = [
  {name: "StyleSheetLayout", notify: refreshStyles},
  {name: "StyleSheetColors", notify: refreshStyles},
  {name: "StyleSheet", notify: refreshStyles},
  {name: "StyleSheetPrint", notify: refreshStyles},
  {name: "PageTemplate", notify: refreshPageTemplate},
  {name: "ColorPalette", notify: refreshColorPalette},
  {name: "NamePatches", notify: refreshSplits},
]

config.refreshers = {
  link: function(e) {
    var title = e.getAttribute("tiddlyLink")
    refreshTiddlyLink(e,title)
    return true
  },

  tiddler: function(e) {
    refreshElements(e)
    return true
  },

  content: function(e) {
    var title = e.getAttribute("tiddler")
    $(e).empty()
    var text = store.getTiddlerText(title)
    if(text) wikify(text,e,null,store.fetchTiddler(title))
    return true
  },

  macro: function(e) {
    var macro = e.getAttribute("macroName")
    var params = e.getAttribute("params")
    if(macro) macro = macros[macro]
    if(macro && macro.refresh) macro.refresh(e,params)
    return true
  }
}

function refreshElements(root)
{
  root.childNodes.forEach(function(e) {
    var refresh = config.refreshers[e.getAttribute && e.getAttribute("refresh")]
    var refreshed = refresh && refresh(e)
    if(e.hasChildNodes() && !refreshed) refreshElements(e)
  })
}

function applyHtmlMacros(root,tiddler)
{
  var e = root.firstChild
  while(e) {
    var nextChild = e.nextSibling
    if(e.getAttribute) {
      var macro = e.getAttribute("macro")
      if(macro) {
        e.removeAttribute("macro")
        var params = ""
        var p = macro.indexOf(" ")
        if(p != -1) {
          params = macro.substr(p+1)
          macro = macro.substr(0,p)
        }
        invokeMacro(e,macro,params,null,tiddler)
      }
    }
    if(e.hasChildNodes()) applyHtmlMacros(e,tiddler)
    e = nextChild
  }
}

function refreshPageTemplate()
{
  var stash = $("<div/>").appendTo("body").hide()[0]
  var display = story.getContainer()
  if(display) {
    var nodes = display.childNodes
    for(var t=nodes.length-1; t>=0; t--)
      stash.appendChild(nodes[t])
  }
  var wrapper = document.getElementById("contentWrapper")
  wrapper.innerHTML = store.getRecursiveTiddlerText("PageTemplate",10)
  applyHtmlMacros(wrapper)
  refreshElements(wrapper)
  display = story.getContainer()
  $(display).empty()
  if(!display) display = createTiddlyElement(wrapper,"div",story.containerId())
  nodes = stash.childNodes
  for(t=nodes.length-1; t>=0; t--) display.appendChild(nodes[t])
  $(stash).remove()
}

function refreshDisplay(title)
{
  var val = $('.searchField').val()
  refreshElements(document.getElementById("contentWrapper"))
  if(title) story.refreshTiddler(title,null,true)
  $('.searchField').val(val)
}

function getPageTitle()
{
  var sub = store.getTiddlerText("SiteSubtitle")
  return store.getTiddlerText("SiteTitle") + (sub && " - " + sub)
}

function refreshStyles(title)
{
  $.twStylesheet(
    title == null ? "" : store.getRecursiveTiddlerText(title,10),
    {id: title, doc: document}
  )
}

function refreshColorPalette(title)
{
  if(startingUp) return
  refreshPageTemplate()
  refreshDisplay()
  refreshStyles("StyleSheetLayout")
  refreshStyles("StyleSheetColors")
  refreshStyles("StyleSheet")
  refreshStyles("StyleSheetPrint")
}

//--
//-- Option handling
//--

function setOption(name,value)
{
  config.options[name] = name.substr(0,3) == "txt" ?
    decodeCookie(value) :
    value == 'true'
}

function loadOptions()
{
  var cookieList = document.cookie.split(';')
  for(var i=0; i < cookieList.length; i++) {
    var p = cookieList[i].indexOf('=')
    if(p != -1)
      if (cookieList[i].substr(0,p).trim() == 'TiddlyWiki') {
        var fields = cookieList[i].substr(p+1).trim().parseParams("anon")
        for(var t=1; t < fields.length; t++)
          setOption(fields[t].name,fields[t].value)
      }
  }
}

function saveOptions()
{
  var options = {}
  for(var key in config.options)
    options[key] = key.substr(0,3) == "txt" ?
      escape(convertUnicodeToHtmlEntities(config.options[key])) :
      config.options[key] ? 'true' : 'false'
  var r = []
  for(var t in options) r.push(t + ':"' + options[t] + '"')
  document.cookie = 'TiddlyWiki=' + r.join(" ") +
    '; expires=Fri, 1 Jan 2038 12:00:00 UTC; path=/'
}

function decodeCookie(s)
{
  s = unescape(s)
  var re = /&#[0-9]{1,5};/g
  return s.replace(re,function($0) {
    return String.fromCharCode(eval($0.replace(/[&#;]/g,'')))})
}

macros.option.genericCreate = function(place,type,opt,className,desc)
{
  var typeInfo = macros.option.types[type]
  var c = document.createElement(typeInfo.elementType)
  if(typeInfo.typeValue)
    c.setAttribute('type',typeInfo.typeValue)
  c[typeInfo.eventName] = typeInfo.onChange
  c.setAttribute('option',opt)
  c.className = className || typeInfo.className
  if(config.optionsDesc[opt])
    c.setAttribute('title',config.optionsDesc[opt])
  place.appendChild(c)
  if(desc != 'no')
    createTiddlyText(place,config.optionsDesc[opt] || opt)
  c[typeInfo.valueField] = config.options[opt]
  return c
}

macros.option.genericOnChange = function(e)
{
  var opt = this.getAttribute('option')
  if(opt) {
    var optType = opt.substr(0,3)
    var handler = macros.option.types[optType]
    if(handler.elementType && handler.valueField)
      macros.option.propagateOption(opt,handler.valueField,
        this[handler.valueField],handler.elementType,this)
  }
  return true
}

macros.option.types = {
  txt: {
    elementType: 'input',
    valueField: 'value',
    eventName: 'onchange',
    className: 'txtOptionInput',
    create: macros.option.genericCreate,
    onChange: macros.option.genericOnChange
  },
  chk: {
    elementType: 'input',
    valueField: 'checked',
    eventName: 'onclick',
    className: 'chkOptionInput',
    typeValue: 'checkbox',
    create: macros.option.genericCreate,
    onChange: macros.option.genericOnChange
  }
}

macros.option.propagateOption = function(opt,valueField,value,elementType,elem)
{
  config.options[opt] = value
  saveOptions()
  var nodes = document.getElementsByTagName(elementType)
  for(var t=0; t < nodes.length; t++) {
    var optNode = nodes[t].getAttribute('option')
    if(opt == optNode && nodes[t]!=elem)
      nodes[t][valueField] = value
  }
}

macros.option.handler = function(place,macroName,params,wikifier,paramString)
{
  params = paramString.parseParams('anon',null,true,false,false)
  var opt = (params[1] && params[1].name == 'anon') ? params[1].value : getParam(params,'name',null)
  var className = (params[2] && params[2].name == 'anon') ? params[2].value : getParam(params,'class',null)
  var desc = getParam(params,'desc','no')
  var type = opt.substr(0,3)
  var h = macros.option.types[type]
  if(h && h.create)
    h.create(place,type,opt,className,desc)
}

//--
//-- Saving
//--

function saveChanges(event)
{
  var do_seed = event.shiftKey
  var t0 = new Date()
  var text = ""
  story.forEachTiddler(function(title) {text += "[[" + title + "]]\n"})
  var dt = store.fetchTiddler("DefaultTiddlers")
  dt.text = text.trimRight()
  dt.modified = new Date()
  macros.unsavedChanges.addChange("DefaultTiddlers", true)
  clearMessage()
  ajaxPost('save', {
      type: wikiType(),
      edition: edition,
      changes: jsonChanges(true)
    },
    function success(response) {
      var r = response.split(",")
      if(r[1]=="clash") {
        _dump("clash between browser edition " + edition + " and " + r[0])
        displayMessage("edition clash")
      } else {
        edition = r[0]
        _dump("successful ruby save of edition " + edition)
        var newFile = r[1]
        if(!newFile) store.setDirty(false)
        dumpM("ruby save " + (new Date()-t0) + " ms", newFile)
        if(do_seed) seed()
      }
    },
    function fail(data, status) {
      message = 'ruby save failed at ' + new Date().convertToYYYYMMDDHHMM()
      dumpM(message)
      _dump(status)
      _dump(data)
    }
  )
}

function wikiType() {
  var path = location.pathname
  if (path == "/Users/rd/Dropbox/fatword.html") return "fat"
  if (path == "/Users/rd/ww/emptys/dev5.html") return "dev"
  return path
}

//--
//-- Filesystem utilities
//--

function convertUnicodeToHtmlEntities(s)
{
  var re = /[^\u0000-\u007F]/g
  return s.replace(re,function($0) {return "&#" + $0.charCodeAt(0).toString() + ";"})
}

//--
//-- TiddlyWiki-specific utility functions
//--

function merge(dst,src)
{
  for(var i in src) if(dst[i] === undefined) dst[i] = src[i]
  return dst
}

// Resolve the target object of an event
function resolveTarget(e)
{
  var obj
  if(e.target)
    obj = e.target
  else if(e.srcElement)
    obj = e.srcElement
  if(obj.nodeType == 3) // defeat Safari bug
    obj = obj.parentNode
  return obj
}

function createTiddlyText(parent,text)
{
  return parent.appendChild(document.createTextNode(text))
}

function createTiddlyCheckbox(parent,caption,checked,onChange)
{
  var cb = document.createElement("input")
  cb.setAttribute("type","checkbox")
  cb.onclick = onChange
  parent.appendChild(cb)
  cb.checked = checked
  cb.className = "chkOptionInput"
  if(caption)
    wikify(caption,parent)
  return cb
}

function createTiddlyElement(parent,element,id,className,text,attribs)
{
  var e = document.createElement(element)
  if(className != null) e.className = className
  if(id != null) e.setAttribute("id",id)
  if(text != null) e.appendChild(document.createTextNode(text))
  if(attribs) for(var n in attribs) e.setAttribute(n,attribs[n])
  if(parent != null) parent.appendChild(e)
  return e
}

function createTiddlyButton(parent,text,tooltip,action,className,id,accessKey,attribs)
{
  var btn = document.createElement("a")
  btn.setAttribute("href","javascript:;")
  if(action) btn.onclick = action
  if(tooltip) btn.setAttribute("title",tooltip)
  if(text) btn.appendChild(document.createTextNode(splitWordsIfRequired(text)))
  btn.className = className || "button"
  if(id) btn.id = id
  if(attribs) for(var i in attribs) btn.setAttribute(i,attribs[i])
  if(parent) parent.appendChild(btn)
  if(accessKey) btn.setAttribute("accessKey",accessKey)
  return btn
}

function createExternalLink(place,url,label)
{
  var link = document.createElement("a")
  link.className = "externalLink"
  var txmt_ = url.indexOf("txmt://") == 0
  var txmt = url.indexOf("txmt://open?url=file://") == 0
  if (txmt_ && !txmt) {
    url = "txmt://open?url=file://" + url.slice(7)
    txmt = true
  }
  var full = url.indexOf("txmt://open?url=file:///") == 0
  var tilde = url.indexOf("txmt://open?url=file://~") == 0
  var href = !txmt || full || tilde ?
    url :
    "txmt://open?url=file://~/" + url.slice(23)
  if(!isUrl(href)) {
    // kludge follows
    href = "file:///Users/rd/Dropbox/" + href
    if (!/\.(html|pdf)(#\S*)?$/.test(href)) {
      href = "txmt://open?url=" + href
      txmt = true
    }
  }
  link.href = href
  link.title = "External link to " + url
  if(!txmt) link.target = "_blank"
  place.appendChild(link)
  if(label) createTiddlyText(link, label)
  return link
}

function getTiddlyLinkInfo(title,currClasses)
{
  var classes = currClasses ? currClasses.split(" ") : []
  classes.pushUnique("tiddlyLink")
  var tiddler = store.findTarget(title)
  if(tiddler) {
    var subTitle = tiddler.getSubtitle()
    classes.pushUnique("tiddlyLinkExisting")
    classes.remove("tiddlyLinkNonExisting")
  } else {
    classes.remove("tiddlyLinkExisting")
    classes.pushUnique("tiddlyLinkNonExisting")
    subTitle = "The tiddler '" + title + "' doesn't yet exist"
  }
  return {
    classes: classes.join(" "),
    subTitle: subTitle,
    targetTitle: tiddler ? tiddler.title : title
  }
}

function onClickTiddlerLink(e)
{
  var target = resolveTarget(e)
  var link = target
  var title = null
  do {
    title = link.getAttribute("tiddlyLink")
    link = link.parentNode
  } while(title == null && link != null)
  if(title)
    if(e.metaKey)
      story.closeTiddler(title)
    else
      story.displayTiddler(target,title,null)
  clearMessage()
}

function createTiddlyLink(place,title,includeText,linkedFromTiddler,referer)
{
  var title = $.trim(title)
  var text = includeText ? title : null
  var i = getTiddlyLinkInfo(title)
  var btn = createTiddlyButton(place,text,i.subTitle,onClickTiddlerLink,i.classes)
  btn.setAttribute("refresh","link")
  btn.setAttribute("tiddlyLink", i.targetTitle)
  if(referer) btn.setAttribute("referer","true")
  return btn
}

function refreshTiddlyLink(e,title)
{
  var i = getTiddlyLinkInfo(title,e.className)
  e.className = i.classes
  e.title = i.subTitle
  e.setAttribute("tiddlyLink",i.targetTitle)
}


function createTiddlyDropDown(place,onchange,options,defaultValue)
{
  var sel = createTiddlyElement(place,"select")
  sel.onchange = onchange
  var t
  for(t=0; t < options.length; t++) {
    var e = createTiddlyElement(sel,"option",null,null,options[t].caption)
    e.value = options[t].name
    if(options[t].name == defaultValue)
      e.selected = true
  }
  return sel
}

//--
//-- TiddlyWiki-specific popup utility functions
//--

function onClickError(e)
{
  var popup = Popup.create(this)
  var lines = this.getAttribute("errorText").split("\n")
  for(var t=0; t < lines.length; t++)
    createTiddlyElement(popup,"li",null,null,lines[t])
  Popup.show()
  e.cancelBubble = true
  e.stopPropagation()
}

function createTiddlyError(place,title,text)
{
  var btn = createTiddlyButton(place,title,null,onClickError,"errorButton")
  if(text) btn.setAttribute("errorText",text)
}

//--
//-- Popup menu
//--

var Popup = {
  stack: [] // Array of objects with members root: and popup:
}

Popup.create = function(root,elem,className)
{
  var stackPosition = this.find(root,"popup")
  Popup.remove(stackPosition+1)
  var popup = createTiddlyElement(document.body,elem || "ol","popup",className || "popup")
  popup.stackPosition = stackPosition
  Popup.stack.push({root: root, popup: popup})
  return popup
}

Popup.onDocumentClick = function(e)
{
  if([undefined, Event.BUBBLING_PHASE, Event.AT_TARGET].includes(e.eventPhase))
    Popup.remove()
  return true
}

Popup.show = function(valign,halign,offset)
{
  var curr = Popup.stack[Popup.stack.length-1]
  this.place(curr.root,curr.popup,valign,halign,offset)
  $(curr.root).addClass("highlight")
  scrollTo(0,ensureVisible(curr.popup))
}

Popup.place = function(root,popup,valign,halign,offset)
{
  if(!offset)
    offset = {x:0,y:0}
  if(popup.stackPosition >= 0 && !valign && !halign) {
    offset.x = offset.x + root.offsetWidth
  } else {
    offset.x = (halign == "right") ? offset.x + root.offsetWidth : offset.x
    offset.y = (valign == "top") ? offset.y : offset.y + root.offsetHeight
  }
  var rootLeft = findPosX(root)
  var rootTop = findPosY(root)
  var popupLeft = rootLeft + offset.x
  var popupTop = rootTop + offset.y
  var winWidth = findWindowWidth()
  if(popup.offsetWidth > winWidth*0.75)
    popup.style.width = winWidth*0.75 + "px"
  var popupWidth = popup.offsetWidth
  var scrollWidth = winWidth - document.body.offsetWidth
  if(popupLeft + popupWidth > winWidth - scrollWidth - 1) {
    if(halign == "right")
      popupLeft = popupLeft - root.offsetWidth - popupWidth
    else
      popupLeft = winWidth - popupWidth - scrollWidth - 1
  }
  popup.style.left = popupLeft + "px"
  popup.style.top = popupTop + "px"
  popup.style.display = "block"
}

Popup.find = function(e)
{
  var t,pos = -1
  for(t=this.stack.length-1; t>=0; t--) {
    if(isDescendant(e,this.stack[t].popup))
      pos = t
  }
  return pos
}

Popup.remove = function(pos)
{
  if(!pos) pos = 0
  if(Popup.stack.length > pos) {
    Popup.removeFrom(pos)
  }
}

Popup.removeFrom = function(from)
{
  var t
  for(t=Popup.stack.length-1; t>=from; t--) {
    var p = Popup.stack[t]
    $(p.root).removeClass("highlight")
    $(p.popup).remove()
  }
  Popup.stack = Popup.stack.slice(0,from)
}

//--
//-- Augmented methods for the JavaScript Array() object
//--

// Return whether an entry exists in an array
Array.prototype.contains = function(item)
{
  return this.indexOf(item) != -1
}

// Push a new value into an array only if it is not already present in the array
// If the optional unique parameter is false, it reverts to a normal push
Array.prototype.pushUnique = function(item,unique)
{
  if(unique === false) this.push(item)
  else if(this.indexOf(item) == -1) this.push(item)
}

Array.prototype.remove = function(item)
{
  var p = this.indexOf(item)
  if(p != -1) this.splice(p,1)
}

//--
//-- Augmented methods for the JavaScript String() object
//--

// Get characters from the right end of a string
String.prototype.right = function(n)
{
  return n < this.length ? this.slice(this.length-n) : this
}

// Trim whitespace from both ends of a string
String.prototype.trim = function()
{
  return this.replace(/^\s*|\s*$/g,"")
}

// Convert a string from a CSS style property name to a JavaScript style name ("background-color" -> "backgroundColor")
String.prototype.unDash = function()
{
  var t,s = this.split("-")
  if(s.length > 1) {
    for(t=1; t < s.length; t++)
      s[t] = s[t].substr(0,1).toUpperCase() + s[t].substr(1)
  }
  return s.join("")
}

// Substitute substrings from an array into a format string that includes '%1'-type specifiers
String.prototype.format = function(s)
{
  var substrings = s && s.constructor == Array ? s : arguments
  var subRegExp = /(?:%(\d+))/mg
  var currPos = 0
  var match,r = []
  do {
    match = subRegExp.exec(this)
    if(match && match[1]) {
      if(match.index > currPos)
        r.push(this.substring(currPos,match.index))
      r.push(substrings[parseInt(match[1])])
      currPos = subRegExp.lastIndex
    }
  } while(match)
  if(currPos < this.length)
    r.push(this.substring(currPos,this.length))
  return r.join("")
}

// Escape any special RegExp characters with that character preceded by a backslash
String.prototype.escapeRegExp = function()
{
  var s = "\\^$*+?()=!|,{}[]."
  var t,c = this
  for(t=0; t < s.length; t++)
    c = c.replace(new RegExp("\\" + s.substr(t,1),"g"),"\\" + s.substr(t,1))
  return c
}

// Convert "\" to "\s", newlines to "\n" (and remove carriage returns)
String.prototype.escapeLineBreaks = function()
{
  return this.replace(/\\/mg,"\\s").replace(/\n/mg,"\\n").replace(/\r/mg,"")
}

// Convert "\n" to newlines, "\b" to " ", "\s" to "\" (and remove carriage returns)
String.prototype.unescapeLineBreaks = function()
{
  return this.replace(/\\n/mg,"\n").replace(/\\b/mg," ").replace(/\\s/mg,"\\").replace(/\r/mg,"")
}

// Convert & to "&amp;", < to "&lt;", > to "&gt;" and " to "&quot;"
String.prototype.htmlEncode = function()
{
  return this.replace(/&/mg,"&amp;").replace(/</mg,"&lt;").replace(/>/mg,"&gt;").replace(/\"/mg,"&quot;")
}

// Convert "&amp;" to &, "&lt;" to <, "&gt;" to > and "&quot;" to "
String.prototype.htmlDecode = function()
{
  return this.replace(/&lt;/mg,"<").replace(/&gt;/mg,">").replace(/&quot;/mg,"\"").replace(/&amp;/mg,"&")
}

// Parse a space-separated string of name:value parameters
// The result is an array of objects:
//   result[0] = object with a member for each parameter name, value of that member being an array of values
//   result[1..n] = one object for each parameter, with 'name' and 'value' members
String.prototype.parseParams =
function(defaultName,defaultValue,allowEval,noNames,cascadeDefaults)
{
  var parseToken = function(match,p) {
    var n
    if(match[p]) n = match[p] // Double quoted
    else if(match[p+1]) n = match[p+1] // Single quoted
    else if(match[p+2]) n = match[p+2] // Double-square-bracket quoted
    else if(match[p+3]) // Double-brace quoted
      try {
        n = match[p+3]
        if(allowEval) n = window.eval(n)
      } catch(ex) {
        _dump("Unable to evaluate {{" + match[p+3] + "}}: " +
          (ex.description || ex.toString()))
      }
    else if(match[p+4]) n = match[p+4] // Unquoted
    else if(match[p+5]) n = "" // empty quote
    return n
  }
  var r = [{}]
  var dblQuote = "(?:\"((?:(?:\\\\\")|[^\"])+)\")"
  var sngQuote = "(?:'((?:(?:\\\\\')|[^'])+)')"
  var dblSquare = "(?:\\[\\[((?:\\s|\\S)*?)\\]\\])"
  var dblBrace = "(?:\\{\\{((?:\\s|\\S)*?)\\}\\})"
  var unQuoted = noNames ? "([^\"'\\s]\\S*)" : "([^\"':\\s][^\\s:]*)"
  var emptyQuote = "((?:\"\")|(?:''))"
  var skipSpace = "(?:\\s*)"
  var token = "(?:" + dblQuote + "|" + sngQuote + "|" + dblSquare + "|" +
    dblBrace + "|" + unQuoted + "|" + emptyQuote + ")"
  var re = noNames ? new RegExp(token,"mg") : new RegExp(skipSpace + token +
    skipSpace + "(?:(\\:)" + skipSpace + token + ")?","mg")
  do {
    var match = re.exec(this)
    if(match) {
      var n = parseToken(match,1)
      if(noNames)
        r.push({name:"",value:n})
      else {
        var v = parseToken(match,8)
        if(v == null && defaultName) {
          v = n
          n = defaultName
        } else if(v == null && defaultValue)
          v = defaultValue
        r.push({name:n,value:v})
        if(cascadeDefaults) {
          defaultName = n
          defaultValue = v
        }
      }
    }
  } while(match)
  // Summarise parameters into first element
  for(var t=1; t < r.length; t++)
    if(r[0][r[t].name]) r[0][r[t].name].push(r[t].value)
    else r[0][r[t].name] = [r[t].value]
  return r
}

// Process a string list of macro parameters into an array. Parameters can be quoted with "", '',
// [[]], {{ }} or left unquoted (and therefore space-separated). Double-braces {{}} results in
// an *evaluated* parameter: e.g. {{config.options.zz}} is eval'd
String.prototype.readMacroParams = function(notAllowEval)
{
  var p = this.parseParams("list",null,!notAllowEval,true)
  var n = []
  for(var t=1; t < p.length; t++) n.push(p[t].value)
  return n
}

twoPad = function(n) { return ("00" + n).slice(-2) }

String.prototype.startsWith = function(prefix)
{
  return !prefix || this.substring(0,prefix.length) == prefix
}

// Returns the first value of the given named parameter.
function getParam(params,name,defaultValue)
{
  if(!params) return defaultValue
  var p = params[0][name]
  return p ? p[0] : defaultValue
}

//--
//-- Augmented methods for the JavaScript Date() object
//--

Date.prototype.formatDay = function() {
  return this.formatString('DD mmm YY')
}

Date.prototype.equals = function(date2) {
  return this.getTime() == date2.getTime()
}

// Substitute date components into a string
Date.prototype.formatString = function(template)
{
  var t = template.replace(/0hh12/g,twoPad(this.getHours12()))
  t = t.replace(/hh12/g,this.getHours12())
  t = t.replace(/0hh/g,twoPad(this.getUTCHours()))
  t = t.replace(/hh/g,this.getUTCHours())
  t = t.replace(/mmm/g,messages.dates.shortMonths[this.getUTCMonth()])
  t = t.replace(/0mm/g,twoPad(this.getMinutes()))
  t = t.replace(/mm/g,this.getMinutes())
  t = t.replace(/0ss/g,twoPad(this.getSeconds()))
  t = t.replace(/ss/g,this.getSeconds())
  t = t.replace(/[ap]m/g,this.getAmPm().toLowerCase())
  t = t.replace(/[AP]M/g,this.getAmPm().toUpperCase())
  t = t.replace(/wYYYY/g,this.getYearForWeekNo())
  t = t.replace(/wYY/g,twoPad(this.getYearForWeekNo()-2000))
  t = t.replace(/YYYY/g,this.getFullYear())
  t = t.replace(/YY/g,twoPad(this.getFullYear()-2000))
  t = t.replace(/MMM/g,messages.dates.months[this.getUTCMonth()])
  t = t.replace(/0MM/g,twoPad(this.getUTCMonth()+1))
  t = t.replace(/MM/g,this.getUTCMonth()+1)
  t = t.replace(/0WW/g,twoPad(this.getWeek()))
  t = t.replace(/WW/g,this.getWeek())
  t = t.replace(/DDD/g,messages.dates.days[this.getDay()])
  t = t.replace(/ddd/g,messages.dates.shortDays[this.getDay()])
  t = t.replace(/0DD/g,twoPad(this.getUTCDate()))
  t = t.replace(/DDth/g,this.getUTCDate()+this.daySuffix())
  t = t.replace(/DD/g,this.getUTCDate())
  var tz = this.getTimezoneOffset()
  var atz = Math.abs(tz)
  t = t.replace(/TZD/g,(tz < 0 ? '+' : '-') + twoPad(Math.floor(atz / 60)) + ':' + twoPad(atz % 60))
  t = t.replace(/\\/g,"")
  return t
}

Date.prototype.getWeek = function()
{
  var dt = new Date(this.getTime())
  var d = dt.getDay()
  if(d==0) d=7;// JavaScript Sun=0, ISO Sun=7
  dt.setTime(dt.getTime()+(4-d)*86400000);// shift day to Thurs of same week to calculate weekNo
  var n = Math.floor((dt.getTime()-new Date(dt.getFullYear(),0,1)+3600000)/86400000)
  return Math.floor(n/7)+1
}

Date.prototype.getYearForWeekNo = function()
{
  var dt = new Date(this.getTime())
  var d = dt.getDay()
  if(d==0) d=7;// JavaScript Sun=0, ISO Sun=7
  dt.setTime(dt.getTime()+(4-d)*86400000);// shift day to Thurs of same week
  return dt.getFullYear()
}

Date.prototype.getHours12 = function()
{
  var h = this.getUTCHours()
  return h > 12 ? h-12 : ( h > 0 ? h : 12 )
}

Date.prototype.getAmPm = function()
{
  return this.getUTCHours() >= 12 ? messages.dates.pm : messages.dates.am
}

Date.prototype.daySuffix = function()
{
  return messages.dates.daySuffixes[this.getDate()-1]
}

// convert a date to UTC string
Date.prototype.convertToYYYYMMDDHHMM = function()
{
  return this.getUTCFullYear() + twoPad(this.getUTCMonth()+1) +
    twoPad(this.getUTCDate()) + twoPad(this.getUTCHours()) +
    twoPad(this.getUTCMinutes())
}

// create a date from a UTC string
Date.convertFromYYYYMMDDHHMM = function(d)
{
  return new Date(Date.UTC(
    parseInt(d.substr(0,4)),
    parseInt(d.substr(4,2))-1,
    parseInt(d.substr(6,2)),
    parseInt(d.substr(8,2)),
    parseInt(d.substr(10,2))
  ))
}

//--
//-- DOM utilities - many derived from www.quirksmode.org
//--

function addEvent(obj,type,fn)
{
  if(obj.attachEvent) {
    obj["e"+type+fn] = fn
    obj[type+fn] = function(){obj["e"+type+fn](event)}
    obj.attachEvent("on"+type,obj[type+fn])
  } else {
    obj.addEventListener(type,fn,false)
  }
}

function removeEvent(obj,type,fn)
{
  if(obj.detachEvent) {
    obj.detachEvent("on"+type,obj[type+fn])
    obj[type+fn] = null
  } else {
    obj.removeEventListener(type,fn,false)
  }
}

// Find the closest relative with a given property value (property defaults to tagName, relative defaults to parentNode)
function findRelated(e,value,name,relative)
{
  name = name || "tagName"
  relative = relative || "parentNode"
  if(name == "className") {
    while(e && !$(e).hasClass(value)) {
      e = e[relative]
    }
  } else {
    while(e && e[name] != value) {
      e = e[relative]
    }
  }
  return e
}

// Get the scroll position for scrollTo necessary to scroll a given element into view
function ensureVisible(e)
{
  var posTop = findPosY(e)
  var posBot = posTop + e.offsetHeight
  var winTop = findScrollY()
  var winHeight = findWindowHeight()
  var winBot = winTop + winHeight
  if(posTop < winTop) {
    return posTop
  } else if(posBot > winBot) {
    if(e.offsetHeight < winHeight)
      return posTop - (winHeight - e.offsetHeight)
    else
      return posTop
  } else {
    return winTop
  }
}

// Get the current width of the display window
function findWindowWidth()
{
  return innerWidth || document.documentElement.clientWidth
}

// Get the current height of the display window
function findWindowHeight()
{
  return innerHeight || document.documentElement.clientHeight
}

// Get the current vertical page scroll position
function findScrollY()
{
  return scrollY || document.documentElement.scrollTop
}

function findPosX(obj)
{
  var curleft = 0
  while(obj.offsetParent) {
    curleft += obj.offsetLeft
    obj = obj.offsetParent
  }
  return curleft
}

function findPosY(obj)
{
  var curtop = 0
  while(obj.offsetParent) {
    curtop += obj.offsetTop
    obj = obj.offsetParent
  }
  return curtop
}

// Blur a particular element
function blurElement(e)
{
  if(e && e.focus && e.blur) {
    e.focus()
    e.blur()
  }
}

// Set the caret position in a text area
function setCaretPosition(e,pos)
{
  if(e.selectionStart || e.selectionStart == '0') {
    e.selectionStart = pos
    e.selectionEnd = pos
    e.focus()
  }
}

// Returns the text of the given (text) node, possibly merging subsequent text nodes
function getNodeText(e)
{
  var t = ""
  while(e && e.nodeName == "#text") {
    t += e.nodeValue
    e = e.nextSibling
  }
  return t
}

// Returns true if the element e has a given ancestor element
function isDescendant(e,ancestor)
{
  while(e) {
    if(e === ancestor) return true
    e = e.parentNode
  }
  return false
}


function loadHotkeys() {
 /*
  * jQuery Hotkeys Plugin
  * Copyright 2010, John Resig
  * Dual licensed under the MIT or GPL Version 2 licenses.
  *
  * Based upon the plugin by Tzury Bar Yochay:
  * https://github.com/tzuryby/jquery.hotkeys
  *
  * Original idea by:
  * Binny V A, http://www.openjs.com/scripts/events/keyboard_shortcuts/
  */

 /*
  * One small change is: now keys are passed by object { keys: '...' }
  * Might be useful, when you want to pass some other data to your handler
  */

 (function(jQuery) {

   jQuery.hotkeys = {
     version: "0.2.0",

     specialKeys: {
       8: "backspace",
       9: "tab",
       10: "return",
       13: "return",
       16: "shift",
       17: "ctrl",
       18: "alt",
       19: "pause",
       20: "capslock",
       27: "esc",
       32: "space",
       33: "pageup",
       34: "pagedown",
       35: "end",
       36: "home",
       37: "left",
       38: "up",
       39: "right",
       40: "down",
       45: "insert",
       46: "del",
       59: ";",
       61: "=",
       96: "0",
       97: "1",
       98: "2",
       99: "3",
       100: "4",
       101: "5",
       102: "6",
       103: "7",
       104: "8",
       105: "9",
       106: "*",
       107: "+",
       109: "-",
       110: ".",
       111: "/",
       112: "f1",
       113: "f2",
       114: "f3",
       115: "f4",
       116: "f5",
       117: "f6",
       118: "f7",
       119: "f8",
       120: "f9",
       121: "f10",
       122: "f11",
       123: "f12",
       144: "numlock",
       145: "scroll",
       173: "-",
       186: ";",
       187: "=",
       188: ",",
       189: "-",
       190: ".",
       191: "/",
       192: "`",
       219: "[",
       220: "\\",
       221: "]",
       222: "'"
     },

     shiftNums: {
       "`": "~",
       "1": "!",
       "2": "@",
       "3": "#",
       "4": "$",
       "5": "%",
       "6": "^",
       "7": "&",
       "8": "*",
       "9": "(",
       "0": ")",
       "-": "_",
       "=": "+",
       ";": ": ",
       "'": "\"",
       ",": "<",
       ".": ">",
       "/": "?",
       "\\": "|"
     },

     // excludes: button, checkbox, file, hidden, image, password, radio, reset, search, submit, url
     textAcceptingInputTypes: [
       "text", "password", "number", "email", "url", "range", "date", "month", "week", "time", "datetime",
       "datetime-local", "search", "color", "tel"],

     // default input types not to bind to unless bound directly
     textInputTypes: /textarea|input|select/i,

     options: {
       filterInputAcceptingElements: true,
       filterTextInputs: true,
       filterContentEditable: true
     }
   };

   function keyHandler(handleObj) {
     if (typeof handleObj.data === "string") {
       handleObj.data = {
         keys: handleObj.data
       };
     }

     // Only care when a possible input has been specified
     if (!handleObj.data || !handleObj.data.keys || typeof handleObj.data.keys !== "string") {
       return;
     }

     var origHandler = handleObj.handler,
       keys = handleObj.data.keys.toLowerCase().split(" ");

     handleObj.handler = function(event) {
       //      Don't fire in text-accepting inputs that we didn't directly bind to
       if (this !== event.target &&
         (jQuery.hotkeys.options.filterInputAcceptingElements &&
           jQuery.hotkeys.textInputTypes.test(event.target.nodeName) ||
           (jQuery.hotkeys.options.filterContentEditable && jQuery(event.target).attr('contenteditable')) ||
           (jQuery.hotkeys.options.filterTextInputs &&
             jQuery.inArray(event.target.type, jQuery.hotkeys.textAcceptingInputTypes) > -1))) {
         return;
       }

       var special = event.type !== "keypress" && jQuery.hotkeys.specialKeys[event.which],
         character = String.fromCharCode(event.which).toLowerCase(),
         modif = "",
         possible = {};

       jQuery.each(["alt", "ctrl", "shift"], function(index, specialKey) {

         if (event[specialKey + 'Key'] && special !== specialKey) {
           modif += specialKey + '+';
         }
       });

       // metaKey is triggered off ctrlKey erronously
       if (event.metaKey && !event.ctrlKey && special !== "meta") {
         modif += "meta+";
       }

       if (event.metaKey && special !== "meta" && modif.indexOf("alt+ctrl+shift+") > -1) {
         modif = modif.replace("alt+ctrl+shift+", "hyper+");
       }

       if (special) {
         possible[modif + special] = true;
       }
       else {
         possible[modif + character] = true;
         possible[modif + jQuery.hotkeys.shiftNums[character]] = true;

         // "$" can be triggered as "Shift+4" or "Shift+$" or just "$"
         if (modif === "shift+") {
           possible[jQuery.hotkeys.shiftNums[character]] = true;
         }
       }

       for (var i = 0, l = keys.length; i < l; i++) {
         if (possible[keys[i]]) {
           return origHandler.apply(this, arguments);
         }
       }
     };
   }

   jQuery.each(["keydown", "keyup", "keypress"], function() {
     jQuery.event.special[this] = {
       add: keyHandler
     };
   });

 })(jQuery || this.jQuery || window.jQuery);
}

// from WhitewordPlugin et al

var bespokeMorpheme
var prettySplits = {}
var unLetter = new RegExp("[^A-Za-z0-9\u00c0-\u00de\u00df-\u00ff\u0150\u0170\u0151\u0171]","g")
var lowerCaseStart = new RegExp("^" + textPrims.lowerLetter)

titleArea = {
  reset: function() {this.top_half = this.time = null},
  changed_half: function(bounds, y) {
    if(!this.time) this.time = new Date()
    if(new Date() - this.time < 300) return false
    var top_half = bounds.bottom - y > y - bounds.top
    var changed = this.top_half != top_half
    this.top_half = top_half
    return changed
  },
  change(elem, text) {
    elem.text(text)
    getSelection().setBaseAndExtent(elem[0], 0, elem[0], 1)
  },
}

makeCopyable = function(elem) {
  elem.mousemove(function(event) {
    if(titleArea.changed_half(this.getBoundingClientRect(),event.clientY)) {
      var title = elem.parent().attr('tiddler')
      var split = splitWordsIfRequired(title)
      var link = asTiddlyLink(title)
      var search = queryNames().name || "here"
      var lower = split.toLowerCase()
      var renamed = search != lower && "[[" + search + "|" + title + "]]"
      lower = "[[" + lower + "]]"
      var simpleSelect = title == split && title == getSelection().toString()
      var text = elem.text()
      if (text == split && !simpleSelect)
        titleArea.change(elem, link)
      else if (text == link && renamed)
        titleArea.change(elem, renamed)
      else if (text == renamed || text == link)
        titleArea.change(elem, lower)
      else
        titleArea.change(elem, link)
    }
  })
  elem.click(function(e) {
    var text = elem.text()
    if(searchText) linkTarget = elem.parent().attr('tiddler')
    e.stopImmediatePropagation()
    titleArea.change(elem, text)
  })
  elem.mouseleave(function() {
    elem.text(splitWordsIfRequired(elem.parent().attr('tiddler')))
    titleArea.reset()
  })
}

String.prototype.capitalize = function() {
  return this.length > 0 ? this[0].toUpperCase() + this.slice(1) : this
}

TiddlyWiki.prototype.findTarget = function(linkString) {
  return store.fetchTiddler(linkString) || tiddlerSplits[linkString.toLowerCase()]
}

// Splitting

var tiddlerSplits = {}

function refreshSplits() {
  prettySplits = {}
  recipes = []
  var patches = store.getTiddlerText("NamePatches")
  patches = patches.split(/\n/)
  for(var i = 0; i < patches.length; i++) {
    var patch = patches[i]
    if(patch != "") {
      if (patch[patch.length - 1] == "*")
        recipes.push(patch.slice(0,-1) + wikiChunk)
      else {
        var lessPretty = patch.replace(unLetter,"")
        if(lessPretty.match(lowerCaseStart))
          lessPretty = lessPretty.capitalize()
        if(patch != lessPretty)
          prettySplits[lessPretty] = patch
        recipes.push(lessPretty)
      }
    }
  }
  bespokeMorpheme = new RegExp("^(" + recipes.join('|') + ")")
  if(!startingUp) {
    refreshDisplay() // was thinking of TabMoreMissing if open
    // refresh links to non-existent tiddlers in open tiddlers
    story.refreshAllTiddlers()
  }
}

cacheTiddlerSplits = function() {
  var t0 = new Date()
  tiddlerSplits = {}
  store.forEachTiddler(function(title,tiddler) {
    tiddlerSplits[tiddler.getSplitName().toLowerCase()] = tiddler
  })
}

var wikiChunk = textPrims.upperLetter + textPrims.lowerLetter + "+"
var basicMorpheme = new RegExp(wikiChunk,"g")

function splitWords(name) {
  var hacks = {
    StyleSheetColors: "Style Sheet Colors",
    StyleSheetLayout: "Style Sheet Layout",
  }
  if(hacks[name]) return hacks[name]
  var split = []
  var prettified = false
  var i = 0
  var match
  while((match = basicMorpheme.exec(name)) != null) {
    var blockOfCaps = match.index > i ? name.slice(i,match.index) : null
    var basicWord = match[0]
    var bespokeMatch = name.slice(i).match(bespokeMorpheme)
    if(bespokeMatch) {
      var bespokeWord = bespokeMatch[0]
      var nextLetter = name[i + bespokeWord.length]
      if(nextLetter == undefined || !nextLetter.match(lowerCaseStart)) {
        var prettyWord = prettySplits[bespokeWord]
        split.push(prettyWord ? prettyWord : bespokeWord)
        prettified = true
        basicMorpheme.lastIndex = i + bespokeWord.length
      } else
        bespokeMatch = null
    }
    if(!bespokeMatch)
      if(blockOfCaps && blockOfCaps == "O")
        split.push("O'" + basicWord)
      else {
        if(blockOfCaps) {
          split.push(blockOfCaps)
          basicMorpheme.lastIndex = i + blockOfCaps.length
        } else
          split.push(basicWord)
      }
    i = basicMorpheme.lastIndex
  }
  if(i < name.length) split.push(name.slice(i))
  return prettified || name.length > 5 ? split.join(" ") : name
}

function isWikiLink(name) {
  return name.match("^" + textPrims.wikiLink + "$")
}

function splitWordsFromPatches(name) {
  return isWikiLink(name) ? splitWords(name) : name
}

function splitWordsIfRequired(name) {
  return store.splitName(name) || splitWordsFromPatches(name)
}

function asTiddlyLink(name)
{
  return isWikiLink(name) ? name : "[[" + (store.splitName(name) || name) + "]]"
}

String.prototype.basicSplit = function() {
  return splitWordsIfRequired(this).toLowerCase()
}

basicCompare = function(a,b) {return a < b ? -1 : (a == b ? 0 : 1)}

basicSplitCompare = function(a,b) {
  return basicCompare(a.basicSplit(), b.basicSplit())
}

Tiddler.prototype.resetSplitName = function()
{
  return this.fields.splitname = splitWordsFromPatches(this.title)
}

Tiddler.prototype.getSplitName = function()
{
  return this.fields.splitname || this.resetSplitName()
}

Tiddler.prototype.basicSplit = function()
{
  return this.getSplitName().toLowerCase()
}

Tiddler.prototype.medited = function()
{
  var dateString = this.fields.medited
  return dateString && Date.convertFromYYYYMMDDHHMM(dateString)
  // new Date(dateString) would be nice
}

Tiddler.prototype.minor = function()
{
  var medited = this.medited()
  return medited && medited > this.modified
}

TiddlyWiki.prototype.splitName = function(title)
{
  var tiddler = this.fetchTiddler(title)
  return tiddler ? tiddler.getSplitName() : null
}

textPrims.separator = /[ .,_\-]/g
textPrims.outlier =
  /[^A-Za-z0-9\u00c0-\u00de\u00df-\u00ff\u0150\u0170\u0151\u0171 .,_\-]/g
textPrims.twoSpaces = /  /g
textPrims.numberFirst = /^\d/

String.prototype.trimInAndOut = function() {
  var lastTrim = ""
  var thisTrim = this.trim()
  while(thisTrim != lastTrim) {
    lastTrim = thisTrim
    thisTrim = lastTrim.replace(textPrims.twoSpaces, " ")
  }
  return thisTrim
}

String.prototype.wikiWordize = function() {
  var trimmed = this.trimInAndOut()
  var parts = trimmed.replace(textPrims.outlier,"").split(" ")
  var len = parts.length
  for (var i = 0; i < len; i++)
    if(textPrims.numberFirst.test(parts[i]))
      parts[i] = parts[i].replace(textPrims.separator, "")
  trimmed = parts.join(' ')
  parts = trimmed.split(textPrims.separator)
  len = parts.length
  var nonEmptyParts = []
  for (i = 0; i < len; i++)
    if(parts[i].length > 0) nonEmptyParts.push(parts[i])
  len = nonEmptyParts.length
  if(len == 0) return null
  if(len == 1) return nonEmptyParts[0]
  var numberFirst = textPrims.numberFirst.test(nonEmptyParts[0])
  var bigEnough = false
  var niceEnough = 0
  for (i = 0; i < len; i++) {
    var big = nonEmptyParts[i].length > 1
    bigEnough = bigEnough || big
    if(!numberFirst && !textPrims.numberFirst.test(nonEmptyParts[i]))
      niceEnough += 1
  }
  if(bigEnough && niceEnough > 1)
    for (i = 0; i < len; i++)
      nonEmptyParts[i] = nonEmptyParts[i].capitalize()
  return bigEnough ? nonEmptyParts.join('') : null
}

function googleWords(name) {
  words = splitWordsIfRequired(name)
  return "[[" + words + '|http://www.google.com/search?q=' +
    words.replace(/ /g, '+') + ']]'
}

macros.splittin = {
  handler: function(place,macroName,params) {
    name = params[0]
    var wrapper=createTiddlyElement(place,"span")
    wikify('splittin: """' + name + ' -> ' + splitWordsIfRequired(name) + '"""',wrapper)
  }
}

macros.makeTable = {
  handler: function(place,macroName,params) {
    var lines = params[0].split('\n')
    for(var t=0; t < lines.length; t++)
      lines[t] = "|" + lines[t].split('\t').join('|') + "|"
    var wrapper=createTiddlyElement(place,"span")
    wikify(lines.join("\n"),wrapper)
  }
}

macros.tiddlerDates = {
  handler: function(place,macroName,params,wikifier,paramString,tiddler) {
    var modified = tiddler.modified.formatDay()
    var created = tiddler.created.formatDay()
    var medited = tiddler.medited()
    var text = modified
    if(medited) text += " medited " + medited.formatDay()
    if(modified != created && !excludeTitle(tiddler.title)) 
      text += " (created " + created + ")"
    $(place).text(text)
  }
}

macros.openTiddlers = {
  handler: function(place) {
    var list = $('<ul></ul>').appendTo(place)
    story.forEachTiddler(function(title,elem) {
      if(elem.id) // if tiddler has not just been closed
        $('<li></li>')
          .append('<span class="close">x</span>')
          .append(createTiddlyLink(null,title,true))
          .appendTo(list)
          .find('span.close')
          .click(function() {
            story.closeTiddler(title)
          })
    })
  },
  refreshList: function(justRolled) {
    var tabsets = $('.tabset')
    if(tabsets.children('.tabSelected').attr('content') == "OpenTiddlers")
      macros.tabs.switchTab(tabsets[0],"Open")
    if(!justRolled) commands.roll.anchor = null
    if(wikiType().length == 3) {
      ajaxPost('order_change', 
        {type: wikiType(), open: JSON.stringify(openTitles())},
        function success() {}, function fail() {})
    }  
  },
}

function allTitles() {
  var titles = []
  store.forEachTiddler(function(title) {titles.push(title)})
  return titles
}

function openTitles() {
  var titles = []
  story.forEachTiddler(function(title,elem) {if(elem.id) titles.push(title)})
  return titles
}

function openTiddlersRaw() {
  return openTitles().map(asTiddlyLink).join("\n") + "\n"
}

macros.openTiddlersRaw = {
  handler: function(place,macroName,params,wikifier,paramString,tiddler) {
    wikify('{{{\n' + openTiddlersRaw() + "}}}",createTiddlyElement(place,"span"))
  }
}

function statf() {
  return "''Total Tiddlers: " + allTitles().length +
    "\nOpenTiddlers: " + openTitles().length + "''\n----\n" + edition
}

macros.statf = {
  handler: function(place,macroName,params,wikifier,paramString,tiddler) {
    wikify(statf(),createTiddlyElement(place,"span"))
  }
}

doSearch = function(text,title,smart) {
  story.search(text,title,smart)
  $('.searchField').val(text).focus()
}

findSelection = function(title) {
  doSearch(getSelection().toString(),title)
}

function findSelectionOuter() {findSelection()}

merge(commands.top,{
  text: "top",
  tooltip: "Move to top"})

merge(commands.drop,{
  text: "drop",
  tooltip: "Move to bottom"})

merge(commands.roll,{
  text: "roll",
  tooltip: "Move down one tiddler"})

merge(commands.expand,{
  text: "expand",
  tooltip: "Open all the tiddlers this one references"})

merge(commands.link,{
  text: "link",
  tooltip: "Link first occurrence of search string"})

commands.top.handler = function(event,src,title)
{
  story.moveToTop(title)
}

Story.prototype.moveToTop = function(title)
{
  var elem = this.getTiddler(title)
  if(elem) {
    clearMessage()
    var place = this.getContainer()
    place.insertBefore(elem,place.firstChild)
    scrollTo(0,ensureVisible(elem))
    macros.openTiddlers.refreshList()
  }
}

commands.drop.handler = function(event,src,title)
{
  var undrop = event.metaKey
  var elem = story.getTiddler(title)
  var place = story.getContainer()
  if(elem) {
    clearMessage()
    if(undrop) var anchor = elem, elem = place.lastChild
    place.insertBefore(elem,undrop ? anchor : null)
    macros.openTiddlers.refreshList()
  }
}

commands.roll.handler = function(event,src,title)
{
  var unroll = event.metaKey
  var elem = story.getTiddler(title)
  var tiddler_elems = []
  story.forEachTiddler(function(title,elem) {tiddler_elems.push(elem)})
  var elem_n = tiddler_elems.indexOf(elem)
  if(unroll) {
    if(elem_n != this.anchor) return
    var next = tiddler_elems[this.target + 1]
    story.getContainer().insertBefore(elem,next)
    macros.openTiddlers.refreshList(true)
    this.target -= 1
    if(this.target == this.anchor) this.anchor = null
  } else {
    if(elem_n != this.anchor) {
      this.anchor = elem_n
      this.target = elem_n + 1
    } else {
      this.target += 1
    }
    var next = tiddler_elems[this.target]
    if(next) {
      story.getContainer().insertBefore(next,elem)
      macros.openTiddlers.refreshList(true)
    } else
      this.target = tiddler_elems.size - 1
  }
}

bulk_change = function(title) {
  var t = store.fetchTiddler(title)
  dumpM("doing bulk change...")
  ajaxPost('bulk_change', {
      type: wikiType(),
      edition: edition,
      title: title,
      changes: jsonChanges(),
    },
    function success(response) {
      var changes = JSON.parse(response)
      var clash = changes.clash
      if(clash) {
        _dump("clash between browser edition " + edition + " and " + clash)
        displayMessage("edition clash")
      } else if(changes.length > 0) {
        dumpM("making " + changes.length + " edits...")
        changes.forEach(function(h) {
          title = h.title
          var t = store.fetchTiddler(title)
          var modified = new Date(h.modified)
          if (modified.equals(t.modified)) { // has to be medited
            t.text = h.text
            t.fields = h.fields
            macros.unsavedChanges.addChange(title, "medited")
            ajaxChangeTiddler(title, "medited", false)
            t.changed()
            store.notify(title)
          } else
            store.saveTiddler(h.title,h.title,h.text,h.modifier,modified,
              h.fields,new Date(h.created),h.creator)
        })
        dumpM("completed")
      } else
        dumpM("no edits found")
    },
    function fail(data, status) {
      _dump('Bulk change failed in ruby for ' + title)
      displayMessage('Bulk change failed in ruby')
    }
  )
}

commands.expand.handler = function(e,src,title)
{
  if (e.altKey) {bulk_change(title); return}
  var titles = story.getLinks(title).filter(i => i !== title)
  if(e.metaKey)
    for(var t = 0; t < titles.length; t++) story.closeTiddler(titles[t])
  else
    story.displayTiddlers(story.getTiddler(title),titles)
}

Story.prototype.getLinks = function(title)
{
  // doesn't dedup
  // this doesn't affect result of expand, only speed
  // DefaultTiddlers doesn't have dups
  return $("#" + this.tiddlerId(title) + " .tiddlyLinkExisting").
    map(function(){return $(this).attr('tiddlylink')}).toArray()
}

function queryNames() {
  var names = {}
  if(!searchText) return names
  names.name = searchText.replace(/(^\,|\,$)/g,"")
  names.Name = names.name.replace(/\w+/g,function(w){
    return w.charAt(0).toUpperCase()+w.substring(1)})
  names.justOne = names.name == names.Name // search only
  names.wikiName = names.Name.replace(/\W/g,"")
  names.wikiName = isWikiLink(names.wikiName) &&
    splitWordsIfRequired(names.wikiName) == names.Name ?
    names.wikiName :
    null
  names.justWiki = names.wikiName == names.name
  names.minimalName = names.wikiName || names.Name
  return names
}

commands.link.handler = function(event,src,title)
{
  if (searchRegex && !config.options.chkRegExp) {
    var unlink = event.metaKey
    var overlink = event.shiftKey
    var action = unlink ? "Unlink" : overlink ? "Overlink" : "Link"
    var t = store.fetchTiddler(title)
    ajaxPost('link', {
        type: wikiType(),
        edition: edition,
        title: title,
        name: queryNames().name,
        target: linkTarget,
        unlink: unlink,
        overlink: overlink,
        action: action,
        changes: jsonChanges(),
      },
      function success(response) {
        var json = JSON.parse(response)
        var clash = json.clash
        if(clash) {
          _dump("clash between browser edition " + edition + " and " + clash)
          displayMessage("edition clash")
        } else if (json.newText != t.text) {
          t.text = json.newText
          t.changed()
          store.saveTiddler(title,title,t.text,"LinkMaker",new Date(),t.fields)
          message = action + "ed " + json.replacer + " in " + title
          dumpM(message)
        }
      },
      function fail(data, status) {
        _dump(action + ' failed in ruby for ' + title)
        displayMessage(action + ' failed in ruby')
      }
    )
  }
}

function getOutput(limit) {
  var limit = limit || 999999
  var text = ""
  store.forEachTiddler(function(title,tiddler) {
    if(limit > 0) {
      text += "<h3>\n" + title + "\n</h3>\n"
      var div = document.createElement("div")
      wikify(tiddler.text, div, null, tiddler)
      var inner = div.innerHTML.replace(/<br>/g, "<br>\n")
      var comment = "<!-- " + "getOutput " + title + " -->\n"
      text += "<div>\n" + inner + "\n</div> " + comment
      limit -= 1
    }
  })
  return text
}

function seed() {
  if(wikiType().length == 3)
    if(macros.unsavedChanges.full.size == 0) {
      dumpM("starting to seed...")
      ajaxPost('seed', {
          type: wikiType(),
          edition: edition,
          output: getOutput(),
        },
        function success(response) {dumpM(response)},
        function fail() {dumpM("seed failure")}
      )
    }
    else dumpM("changes must be empty for seed to be run")
  else dumpM("must be fat or dev for seed to be run")
}
