# wiki_text.rb

Names = Struct.new(:name, :Name, :justOne, :wikiName, :justWiki, :minimalName)

class WikiText
  attr_reader :content

  def initialize(content)
    @content = content
    @blanked = content
  end

  def esc(regex_fragment)
    Regexp.escape(regex_fragment)
  end

  def blank(pre, post=pre)
    @blanked.gsub!(/#{esc(pre)}((?:.|\n)*?)#{esc(post)}/) {|s| " " * s.size}
  end

  def blank_tag(tag)
    blank("<#{tag}>", "</#{tag}>")
  end

  def basic_content
    blank("/%", "%/")
    blank("{{{", "}}}")
    blank('"""')
    blank_tag("nowiki")
    blank_tag("html")
    blank_tag("script")
    @blanked
  end

  def isWikiLink(name)
    name =~ /^#{Regex.wikiLink}$/
  end

  def queryNames(wiki, searchText)
    names = Names.new
    names.name = searchText.gsub(/(^\,|\,$)/,"").gsub(/\,/," ")
    names.Name = names.name.gsub(/\w+/) {|s| s[0] = s[0].upcase; s}
    names.justOne = names.name == names.Name
    names.wikiName = names.Name.gsub(/\W/,"")
    # hopefully wiki.splitName does all that splitWordsIfRequired did
    names.wikiName = isWikiLink(names.wikiName) &&
      wiki.splitName(names.wikiName) == names.Name ?
      names.wikiName : nil
    names.justWiki = names.wikiName == names.name
    names.minimalName = names.wikiName || names.Name
    names
  end

  def link(wiki, searchText)
    names = queryNames(wiki, searchText)
    qq :names if $d
    newText = @content
    forBracketting = /#{names.name}/i # needs an esc?
    match = newText.match(forBracketting)
    if match
      replacer = "[[" + match[0] + "]]"
      qq :replacer if $d
      newText = newText.gsub(forBracketting, replacer)
    end
    newText
  end
end
