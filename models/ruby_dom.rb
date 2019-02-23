# ruby_dom.rb

require 'tiddler'

module CGI::Util
  def h3(string) # who knows
    string.gsub(/[&<>]/, TABLE_FOR_ESCAPE_HTML__)
  end
end

class RubyDOM
  def initialize(tag=nil, closing=tag)
    @tag = tag
    @closing = closing
    @attributes = ""
    @children = []
  end

  def self.single(tag)
    new(tag, false)
  end

  def open_tag
    @tag ? "<#{@tag}#{@attributes}>" : ""
  end

  def []= attribute, value
    @attributes << " #{Tiddler.attribute_phrase attribute, value}"
  end

  def method_missing(name, *args)
    args.size == 1 && name[-1] == "=" && self[name[0..-2]] = args[0] ||
    super.method_missing(name, *args)
  end

  def close_tag
    @closing ? "</#{@tag}>" : ""
  end

  def strip
    @strip = true
  end

  def to_s
    "#{open_tag}#{@strip ? inner.strip : inner}#{close_tag}"
  end

  def inner
    @children.map(&:to_s).join
  end

  def innerHTML(html)
    inner = html.gsub(/\s+\/?>/, '>')
    inner = inner.gsub('&mdash;', "—")
    inner = inner.gsub(/<\/(param|embed)>/, "")
    inner = inner.gsub(/(<(param|embed|img)\s+[^>]+)\/>/, '\\1>')
    inner = inner.gsub(/<br\/>/, '<br>')
    %w{border webkitAllowFullScreen mozallowfullscreen allowfullscreen noresize
    controls async}.each do |key|
      inner = inner.gsub(/( #{key})(>| )/i, '\\1=""\\2')
    end
    inner = inner.gsub(/<\/object>/, '') unless inner.index('<object')
    inner = inner.gsub(/(<td.*?>|<\/td>)/, '') unless inner.index('<table')
    inner = inner.gsub(/<\/object><\/object>/, '</object>')
    inner = inner.gsub(/(<noscript>)(.*)(<\/noscript>)/) do
      "#{$1}#{CGI::h3($2)}#{$3}"
    end
    inner = inner.gsub(/\s+([^= ]+)= *(?:"(.*?)"|'(.*?)'|([^"' >]+))/) do
      " #{$1.downcase}=\"#{CGI::h3(CGI.unescapeHTML($2||$3||$4))}\""
    end
    inner = inner.gsub(/"([^"= ]+)="([^"]*)/) do
      "\" #{$1.downcase}=\"#{CGI::h3(CGI.unescapeHTML($2))}"
    end
    inner = inner.gsub(/(<param [^>]*?) name="[^ ">]*">/, '\\1>')
    inner = inner.gsub(/ name=\"flashPlayer\">/, ">")
    inner = inner.gsub(/^(<iframe[^>]*>)$/, "\\1<\/iframe>")
    @children << inner
    self
  end

  def decode(codes)
    if codes == "&nbsp;"
      @children << codes
    else
      self << CGI.unescapeHTML(codes)
    end
    self
  end

  def <<(output)
    escaped = output.is_a?(String) ? CGI::h3(output) : output
    @children << escaped
    self
  end
end
