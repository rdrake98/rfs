# wikifier_null.rb

require 'wikifier'
require 'ruby_dom_null'

class WikifierNull < Wikifier
  def self.node_type; RubyDOMNull; end

  def self.formatters
    if !@formatters
      @formatters = @@formatters.dup
      @formatters.each_with_index {|hash, i| @formatters[i] = hash.dup}
      @formatters[5][:handler] = -> w {w.output << "     "}
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
