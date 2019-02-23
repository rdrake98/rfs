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
    name = searchText.gsub(/(^\,|\,$)/,"").gsub(/\,/," ")
    dName = name.gsub(/\w+/) {|s| s[0] = s[0].upcase; s}
    justOne = name == dName
    wikiName = dName.gsub(/\W/,"")
    # hopefully wiki.splitName does all that splitWordsIfRequired did
    wikiName = isWikiLink(wikiName) && wiki.splitName(wikiName) == dName ?
      wikiName : nil
    justWiki = wikiName == name
    minimalName = wikiName || dName
    Names.new(name, dName, justOne, wikiName, justWiki, minimalName)
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
