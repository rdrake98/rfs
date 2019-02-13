# wiki_text.rb

class WikiText
  attr_reader :content

  def initialize(content)
    @content = content
    @reduced = content
  end

  def reduce(before, after=before)
    pre = Regexp.escape(before)
    post = Regexp.escape(after)
    @reduced.gsub!(Regexp.new("#{pre}((?:.|\\n)*?)#{post}"), "")
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
