# wikifier.rb

require 'ruby_dom'
require 'regex'

X = $t1 && []
XX = $t1 && Struct.new(:tiddler, :type)
require 'dd' if $dd
require 'd' if $d

class Wikifier
  attr_reader :output, :matchText, :source, :matchStart, :wiki
  attr_accessor :nextMatch

  def add_element(tag, regex, output=@output)
    element = RubyDOM.new(tag)
    subWikifyTerm(element, regex)
    output << element
    element
  end

  def createExternalLink(text, link=text, image=false)
    a = RubyDOM.new("a")
    a.class = image ? "externalLink imageLink" : "externalLink"
    txmt_ = link.index("txmt://") == 0
    txmt = link.index("txmt://open?url=file://") == 0
    if txmt_ && !txmt
      link = "txmt://open?url=file://" + link[7..-1]
      txmt = true
    end
    full = link.index("txmt://open?url=file:///") == 0
    tilde = link.index("txmt://open?url=file://~") == 0

    href = !txmt || full || tilde ?
      link :
      "txmt://open?url=file://~/" + link[23..-1]
    unless href =~ /#{Regex.urlPattern}/
      href = "file://" + (href[0] == "/" ? "" : @wiki.parent_dir) + href
      unless href =~ /\.(html|pdf)(#\S*)?$/
        href = "txmt://open?url=" + href
        txmt = true
      end
    end

    a.href = href
    a.title = "External link to #{link}"
    a.target = "_blank" if !txmt
    a << text
    @output << a
  end

  def createTiddlyLink(text, link=nil, image=false)
    a = RubyDOM.new("a")
    a.href = "javascript:;"
    link_text = link || text.strip
    tiddler = @wiki.referent(link_text)
    a.title = tiddler ?
      "#{tiddler.title} - #{tiddler.modified.to_minute}" :
      "The tiddler '#{link_text}' doesn't yet exist"
    classes = ["tiddlyLink"]
    classes << (tiddler ? "tiddlyLinkExisting" : "tiddlyLinkNonExisting")
    classes << "imageLink" if image
    a.class = classes.join(" ")
    a.refresh = "link"
    a.tiddlylink = tiddler&.title || link_text
    a << if text
      text
    elsif tiddler
      title = tiddler.title
      splitname = tiddler.splitname
      title.size < 6 && splitname.size == title.size ?
        @wiki.pretty(link) ? splitname : link :
        splitname == title && link != title ?
          @wiki.splitNameFromPatches(link) :
          splitname
    else
      @wiki.splitNameFromPatches(link)
    end
    @output << a
  end

  @formatters = [
    {
      type: :table,
      match: "^\\|(?:[^\\n]*)\\|(?:\n|$)",
      handler: -> w do
        text = w.matchText
        table = RubyDOM.new("table")
        table.class = "twtable"
        tbody = RubyDOM.new("tbody")
        table << tbody
        regex = /^\|.*?\|$/
        even_row = true
        position = w.matchStart
        while (match = regex.match(w.source, position))&.begin(0) == position
          tr = RubyDOM.new("tr")
          tr.class = even_row ? "evenRow" : "oddRow"
          even_row = !even_row
          tbody << tr
          position += 1
          colspan =  1
          while position < match.end(0) - 1
            td_match = /(?:(>)| *(!)?(.*?))\|/.match(w.source, position)
            # byebug if $dd # and $t == "$#####"
            if td_match[1]
              colspan += 1
              w.nextMatch = td_match.end(0)
            else
              td = RubyDOM.new(td_match[2] ? "th" : "td")
              tr << td
              w.nextMatch = td_match.begin(3)
              w.subWikifyTerm(td, / *\|/)
              if colspan > 1
                td.colspan = colspan
                colspan = 1
              end
              regex = /( *)!?.*?( *)\|$/
              td_match = regex.match(w.source[0...w.nextMatch], position)
              # q "w.source[0...w.nextMatch]" if $d
              right = td_match[1].size > 0
              left = td_match[2].size > 0
              td.align = "center" if left and right
              td.align = "left" if left and !right
              td.align = "right" if !left and right
              td.rstrip
            end
            position = td_match.end(0)
            position = w.nextMatch if w.nextMatch > position
          end
          position += 1
        end
        w.output << table
        w.nextMatch = position
      end
    },
    {
      type: :heading,
      match: "^!{1,6}",
      handler: -> w {w.add_element("h" + w.matchText.size.to_s, /\n/m)}
    },
    {
      type: :list,
      match: "^[*#]{1,2}",
      handler: -> w do
        type = w.matchText[0] == "*" ? "ul" : "ol"
        list = RubyDOM.new(type)
        regex = /^([*#]{1,2})(.*)$/
        latest1 = list
        old_level = 1
        position = w.matchStart
        while (match = regex.match(w.source, position))&.begin(0) == position
          w.nextMatch = match.end(1)
          new_level = match[1].size
          if new_level == 1
            latest1 = w.add_element("li", /$/, list)
          else
            latest1 << (latest2 = RubyDOM.new(type)) if old_level == 1
            w.add_element("li", /$/, latest2)
          end
          old_level = new_level
          position = match.end(0) + 1
        end
        w.output << list
        w.nextMatch = position
      end
    },
    {
      type: :quoteByBlock,
      match: "^<<<\\n",
      handler: -> w {w.add_element("blockquote", /^<<<(\n|$)/)}
    },
    {
      type: :quoteByLine,
      match: "^>{1,2}",
      handler: -> w do
        # byebug if $dd and $t == "$$$#"
        block = RubyDOM.new("blockquote")
        regex = /^(>{1,2})(.*)$/
        old_level = 1
        position = w.matchStart
        while (match = regex.match(w.source, position))&.begin(0) == position
          w.nextMatch = match.begin(2)
          new_level = match[1].size
          if new_level == 1
            w.subWikifyTerm(block, /(\n|$)/)
            block << RubyDOM.single("br")
          else
            block << (block2 = RubyDOM.new("blockquote")) if old_level == 1
            w.subWikifyTerm(block2, /(\n|$)/)
            block2 << RubyDOM.single("br")
          end
          old_level = new_level
          position = match.end(0) + 1
        end
        w.output << block
      end
    },
    {
      type: :rule,
      match: "^----+$\\n?|<hr ?/?>\\n?",
      handler: -> w {w.output << RubyDOM.single("hr")}
    },
    {
      type: :monospacedByLine,
      match: Regex.monospaced_initial,
      handler: -> w do
        regex = Regex.monospaced[w.matchText.chomp]
        match = regex.match(w.source, w.matchStart)
        if match&.begin(0) == w.matchStart
          pre = RubyDOM.new("pre")
          pre << match[1]
          w.output << pre
          w.nextMatch = match.end(0)
        end
      end
    },
    {
      type: :wikifyComment,
      match: "^(?:/\\*\\*\\*|<!---)\\n",
      handler: -> w do
        regex = w.matchText == "/***\n" ? /(^\*\*\*\/\n)/m : /(^--->\n)/m
        w.add_element(nil, regex)
      end
    },
    {
      type: :macro,
      match: "<<",
      handler: -> w do
        regex = /<<([^>\s]+)(?:\s*)((?:[^>]|(?:>(?!>)))*)>>/m
        match = regex.match(w.source, w.matchStart)
        if match&.begin(0) == w.matchStart
          element = RubyDOM.new("span")
          element << match[0]
          w.output << element
          w.nextMatch = match.end(0)
        end
      end
    },
    {
      type: :prettyLink,
      match: "\\[\\[",
      handler: -> w do
        regex = /\[\[(.*?)(?:\|(~)?(.*?))?\]\]/m
        match = regex.match(w.source, w.matchStart)
        if match&.begin(0) == w.matchStart
          text = match[1]
          if match[3]
            # Pretty bracketted link
            link = match[3]
            whole = "#{text}|#{match[2]}#{link}"
            if w.wiki.referent(whole)
              w.createTiddlyLink(whole)
            elsif !match[2] && w.wiki.external_link?(link)
              w.createExternalLink(text, link)
            else
              w.createTiddlyLink(text, link)
            end
          else
            # Simple bracketted link
            w.createTiddlyLink(text)
          end
          w.nextMatch = match.end(0)
        end
      end
    },
    {
      type: :wikiLink,
      match: "~?" + Regex.wikiLink,
      handler: -> w do
        if w.matchText[0] == "~"
          w.output << w.matchText[1..-1]
          return
        end
        if w.matchStart > 0
          match = Regex.anyLetterR.match(w.source, w.matchStart - 1)
          if match.begin(0) == w.matchStart - 1
            # puts w.matchText
            w.output << w.matchText
            return
          end
        end
        w.createTiddlyLink(nil, w.matchText)
      end
    },
    {
      type: :urlLink,
      match: Regex.urlPattern,
      handler: -> w {w.createExternalLink(w.matchText)}
    },
    {
      type: :image,
      match: "\\[[<>]?[Ii][Mm][Gg]\\[",
      handler: -> w do
        regex = /\[([<]?)(>?)[Ii][Mm][Gg]\[([^\[\]\|]+)\](?:\[([^\]]*)\])?\]/m
        match = regex.match(w.source, w.matchStart)
        if match&.begin(0) == w.matchStart
          img = RubyDOM.single("img")
          img.align = "left" if match[1].size > 0
          img.align = "right" if match[2].size > 0
          src = match[3].split(' ')
          img.src = src[0]
          if src[1]
            img.width = src[1]
          elsif match[3][-1] == " " && !img.align
            img.width = 610 # same for fat and dev on mg
          end
          if img.align
            img.style = "margin-" +
            (img.align == "right" ? "left: " : "right: ") +
            (src[2] || "10") + "px;"
          end
          (link = match[4]) ?
            w.wiki.external_link?(link) ?
              w.createExternalLink(img, link, true) :
              w.createTiddlyLink(img, link, true) :
            w.output << img
          w.nextMatch = match.end(0)
        end
      end
    },
    {
      type: :html,
      match: "<[Hh][Tt][Mm][Ll]>",
      handler: -> w do
        regex = /<[Hh][Tt][Mm][Ll]>((?:.|\n)*?)<\/[Hh][Tt][Mm][Ll]>/m
        match = regex.match(w.source, w.matchStart)
        if match&.begin(0) == w.matchStart
          span = RubyDOM.new("span")
          span.innerHTML(match[1])
          w.output << span
          w.nextMatch = match.end(0)
        end
      end
    },
    {
      type: :commentByBlock,
      match: "/%",
      handler: -> w do
        match = /\/%((?:.|\n)*?)%\//m.match(w.source, w.matchStart)
        w.nextMatch = match.end(0) if match&.begin(0) == w.matchStart
      end
    },
    {
      type: :characterFormat,
      match: Regex.format_match,
      handler: -> w do
        tags = Regex.format_tags
        w.add_element(tags[w.matchText], /(#{Regexp.escape(w.matchText)})/m)
      end
    },
    {
      type: :code,
      match: "\\{\\{\\{",
      handler: -> w do
        regex = /\{\{\{((?:.|\n)*?)\}\}\}/m
        match = regex.match(w.source, w.matchStart)
        if match&.begin(0) == w.matchStart
          w.output << (RubyDOM.new("code") << match[1])
          w.nextMatch = match.end(0)
        end
      end
    },
    {
      type: :customFormat,
      match: "@@",
      handler: -> w do
        regex = /@@(?:color\((.*?)\):)?(.*?)@@/
        match = regex.match(w.source, w.matchStart)
        if match&.begin(0) == w.matchStart
          w.nextMatch = match.begin(2)
          span = w.add_element("span", /@@/m)
          match[1] ?
            span.style = "color: #{match[1]};" :
            span.class = "marked"
          w.nextMatch = match.end(0)
        end
      end
    },
    {
      type: :mdash,
      match: "--",
      handler: -> w do
        span = RubyDOM.new("span")
        span << "—"
        w.output << span
      end
    },
    {
      type: :lineBreak,
      match: "\\n|<br ?/?>",
      handler: -> w {w.output << RubyDOM.single("br")}
    },
    {
      type: :rawText,
      match: "\"{3}|<nowiki>",
      handler: -> w do
        regex = /(?:\"{3}|<nowiki>)((?:.|\n)*?)(?:\"{3}|<\/nowiki>)/m
        match = regex.match(w.source, w.matchStart)
        if match&.begin(0) == w.matchStart
          element = RubyDOM.new("span")
          element << match[1]
          w.output << element
          w.nextMatch = match.end(0)
        end
      end
    },
    {
      type: :htmlEntitiesEncoding,
      match: Regex.html_entities_match,
      handler: -> w do
        element = RubyDOM.new("span")
        element.decode(w.matchText)
        w.output << element
      end
    },
  ]
  @big_regex = /(#{@formatters.map{|f|"(#{f[:match]})"}.join("|")})/m

  def self.formatters; @formatters; end
  def self.big_regex; @big_regex; end
  def formatters; self.class.formatters; end
  def big_regex; self.class.big_regex; end

  def initialize(source, wiki)
    @source = source
    @wiki = wiki
    @nextMatch = 0
  end

  def wikify
    @output = RubyDOM.new
    subWikify(@source)
    @output.to_s
  end

  def subWikifyTerm(output, termRegex)
    oldOutput = @output
    @output = output
    while termMatch = termRegex.match(@source, @nextMatch)
      subWikify(@source[0..(termMatch&.begin(0).to_i - 1)])
      termEnd = termMatch.end(0)
      if termEnd >= @nextMatch
        @nextMatch = termEnd
        break
      end
    end
    @output = oldOutput
  end

  def subWikify(source)
    while match = big_regex.match(source, @nextMatch)
      @matchStart = match.begin(0)
      @output << source[@nextMatch...@matchStart] if @matchStart > @nextMatch
      @matchText = match[0]
      @nextMatch = match.end(0)
      formatter = formatters[match[2..-1].index(&:itself)]
      X << XX.new($t, formatter[:type]) if $t1
      binding.pry if $dd
      formatter[:handler].(self)
    end
    if @nextMatch < source.size
      @output << source[@nextMatch..-1]
      @nextMatch = source.size
    end
  end
end
