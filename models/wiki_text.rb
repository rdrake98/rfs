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
    _Name = name.gsub(/\w+/) {|s| s[0] = s[0].upcase; s}
    justOne = name == _Name
    wikiName = _Name.gsub(/\W/,"")
    # hopefully wiki.splitName does all that splitWordsIfRequired did
    wikiName = isWikiLink(wikiName) && wiki.splitName(wikiName) == _Name ?
      wikiName : nil
    justWiki = wikiName == name
    minimalName = wikiName || _Name
    Names.new(name, _Name, justOne, wikiName, justWiki, minimalName)
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
      newText = newText.sub(forBracketting, replacer)
    end
    newText
  end
end
