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

  def self.isWikiLink(name)
    name =~ /^#{Regex.wikiLink}$/
  end

  def queryNames(wiki, searchText)
    name = searchText.gsub(/(^\,|\,$)/,"").gsub(/\,/," ")
    _Name = name.gsub(/\w+/) {|s| s[0] = s[0].upcase; s}
    justOne = name == _Name
    wikiName = _Name.gsub(/\W/,"")
    wikiName = self.class.isWikiLink(wikiName) &&
      wiki.splitName(wikiName) == _Name ? wikiName : nil
    justWiki = wikiName == name
    minimalName = wikiName || _Name
    Names.new(name, _Name, justOne, wikiName, justWiki, minimalName)
  end

  def link(wiki, searchText, target, unlink, overlink)
    # byebug if $dd
    names = queryNames(wiki, searchText)
    newText = @content
    startPos = index = 0
    if unlink || overlink
      bracketted = /#{esc("[[")}(#{esc(names.name)})#{esc("]]")}/i
      bmatch = newText.match(bracketted)
      wikied = /#{Regex.startWikiWord}#{names.wikiName}#{Regex.endWord}/
      wmatch = names.wikiName && newText.match(wikied)
      return [newText, ""] if !bmatch && !wmatch
      bmatch = nil if bmatch && wmatch && wmatch.begin(0) < bmatch.begin(0)
      replacer = bmatch ?
        bmatch[0] :
        names.wikiName + (names.justWiki ? " to ~" + names.wikiName : "")
      regex = bmatch ? bracketted : wikied
      replacement = bmatch ?
        bmatch[1] :
        wmatch[1] + (names.justWiki ? "~" : "") + names.Name + wmatch[2]
      newText = newText.sub(regex, replacement)
      startPos = (bmatch || wmatch).begin(0) + replacement.length if overlink
    end
    if !unlink
      forWikiing = /#{Regex.startWord}#{names.Name}#{Regex.endWord}/
      forBracketting = /#{esc(names.name)}/i
      textForLink = newText[startPos..-1]
      offset = 0
      blanked = WikifierNull.new(newText, wiki).wikify[startPos..-1]
      match = blanked.match(forBracketting)
      if match
        wikiNameIndex = names.minimalName == names.wikiName ?
          blanked =~ forWikiing : nil
        offset = match.begin(0)
        replacer = target ? "[[" + match[0] + "|" + target + "]]" :
          wikiNameIndex && offset - wikiNameIndex > -1 ?
            names.wikiName : "[[" + match[0] + "]]"
        textForLink = textForLink[offset..-1].sub(forBracketting, replacer)
      end
      newText = newText[0...startPos+offset] + textForLink
    end
    [newText, replacer]
  end
end
