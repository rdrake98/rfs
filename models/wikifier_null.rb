# wikifier_null.rb

require 'wikifier'
require 'ruby_dom_null'

class WikifierNull < Wikifier
  def self.node_type; RubyDOMNull; end

  def self.set_handler(type, handler)
    @formatters.find{|f| f[:type] == type }[:handler] = handler
  end

  def self.spaceout(regex=nil)
    return -> w {w.output << " " * w.matchText.size} unless regex
    -> w do
      match = regex.match(w.source, w.matchStart)
      if match&.begin(0) == w.matchStart
        w.output << " " * match[0].size
        w.nextMatch = match.end(0)
      end
    end
  end

  def keep_inner(regex)
    @output << " " * matchText.size
    element = node_type.new("nulltag")
    termMatch = subWikifyTerm(element, regex)
    @output << element
    @output << " " * termMatch[0].size
  end

  def self.formatters
    if !@formatters
      @formatters = @@formatters.dup
      @formatters.each_with_index {|hash, i| @formatters[i] = hash.dup}
      set_handler(:heading, spaceout)
      set_handler(:rule, spaceout)
      set_handler(:lineBreak, spaceout)
      set_handler(:htmlEntitiesEncoding, spaceout)
      set_handler(:mdash, spaceout)
      set_handler(:html,
        spaceout(/<[Hh][Tt][Mm][Ll]>((?:.|\n)*?)<\/[Hh][Tt][Mm][Ll]>/m))
      set_handler(:rawText,
        spaceout(/(?:\"{3}|<nowiki>)((?:.|\n)*?)(?:\"{3}|<\/nowiki>)/m))
      set_handler(:customFormat, spaceout(/@@(?:color\((.*?)\):)?(.*?)@@/))
      set_handler(:code, spaceout(/\{\{\{((?:.|\n)*?)\}\}\}/m))
      set_handler(:quoteByBlock, -> w {w.keep_inner(/^<<<(\n|$)/)})
    end
    @formatters
  end

  def self.big_regex
    if !@big_regex
      @big_regex = /(#{formatters.map{|f|"(#{f[:match]})"}.join("|")})/m
    end
    @big_regex
  end
end
