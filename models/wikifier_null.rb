# wikifier_null.rb

require 'wikifier'
require 'ruby_dom_null'

class WikifierNull < Wikifier
  def self.node_type; RubyDOMNull; end
  def self.node_type_new(tag); node_type.new(tag); end

  # def add_element(tag, regex, output=@output)
  #   element = node_type.new(tag)
  #   subWikifyTerm(element, regex)
  #   output << element
  #   element
  # end

  def self.formatters
    if !@formatters
      @formatters = @@formatters.dup
      @formatters.each_with_index {|hash, i| @formatters[i] = hash.dup}
      # @formatters = @formatters[3..3]
      # f = @formatters[3]
      # f[:handler] =
    end
    @formatters
  end

  def self.big_regex
    if !@big_regex
      @big_regex = /(#{formatters.map{|f|"(#{f[:match]})"}.join("|")})/m
    end
    @big_regex
  end

  def wikify
    byebug if $dd
    @output = node_type.new
    subWikify(@source)
    @output.to_s
  end
end
