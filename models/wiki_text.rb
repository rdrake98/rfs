# wiki_text.rb

Names = Struct.new(:name, :Name, :justOne, :wikiName, :justWiki, :minimalName)

class WikiText
  attr_reader :content

  def initialize(content)
    @content = content
    @blanked = content.dup
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
    wikiName = isWikiLink(wikiName) && wiki.splitName(wikiName) == _Name ?
      wikiName : nil
    justWiki = wikiName == name
    minimalName = wikiName || _Name
    Names.new(name, _Name, justOne, wikiName, justWiki, minimalName)
  end

  def link(wiki, searchText, unlink, overlink)
    newText = @content
    names = queryNames(wiki, searchText)
    if !unlink
      byebug if $dd
      forWikiing = /#{Regex.startWord}#{names.Name}#{Regex.endWord}/
      if names.justWiki
      else
        forBracketting = /#{esc(names.name)}/i
        match = newText.match(forBracketting)
        if match
          wikiNameIndex = names.minimalName == names.wikiName ?
            newText =~ forWikiing : nil
          replacer = wikiNameIndex && match.begin(0) - wikiNameIndex > -1 ?
            names.wikiName : "[[" + match[0] + "]]"
          newText = newText.sub(forBracketting, replacer)
        end
      end
    end
    newText
  end
end
