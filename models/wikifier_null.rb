# wikifier_null.rb

require 'wikifier'
require 'ruby_dom_null'

class WikifierNull < Wikifier
  def self.node_type; RubyDOMNull; end

  def self.set_handler(type, handler)
    @formatters.find{|f| f[:type] == type }[:handler] = handler
  end

  def self.formatters
    if !@formatters
      @formatters = @@formatters.dup
      @formatters.each_with_index {|hash, i| @formatters[i] = hash.dup}
      spaceout = -> w {w.output << " " * w.matchText.size}
      set_handler(:heading, spaceout)
      set_handler(:rule, spaceout)
      set_handler(:lineBreak, -> w {w.output << "\n"})
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
