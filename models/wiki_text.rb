# wiki_text.rb

class WikiText
  attr_reader :content

  def initialize(content)
    @content = content
  end

  def basic_content
    @content.gsub(/\/%((?:.|\n)*?)%\//,"").
      gsub(/\{{3}((?:.|\n)*?)\}{3}/,"").
      gsub(/"""((?:.|\n)*?)"""/,"").
      gsub(/<nowiki\>((?:.|\n)*?)<\/nowiki\>/,"").
      gsub(/<html\>((?:.|\n)*?)<\/html\>/,"").
      gsub(/<script((?:.|\n)*?)<\/script\>/,"")
  end
end
