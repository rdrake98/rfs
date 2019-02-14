# wiki_text.rb

class WikiText
  attr_reader :content

  def initialize(content)
    @content = content
    @reduced = content
  end

  def esc(regex_fragment)
    Regexp.escape(regex_fragment)
  end

  def reduce(before, after=before)
    @reduced.gsub!(/#{esc(before)}((?:.|\n)*?)#{esc(after)}/, "")
  end

  def reduce_tag(tag)
    reduce("<#{tag}>", "</#{tag}>")
  end

  def basic_content
    reduce("/%", "%/")
    reduce("{{{", "}}}")
    reduce('"""')
    reduce_tag("nowiki")
    reduce_tag("html")
    reduce_tag("script")
    @reduced
  end
end
