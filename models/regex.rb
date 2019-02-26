# regex.rb

class Regex
  def self.initialize
    @urlPattern = "(?:file|http|https|mailto|ftp|irc|news|data):[^\\s'\"]+(?:/|\\b)"
    upperLetter = "[A-Z\u00c0-\u00de\u0150\u0170]"
    @upperStart = /^#{upperLetter}/
    lowerLetter = "[a-z0-9\u00df-\u00ff\u0151\u0171]"
    anyLetter   = "[A-Za-z0-9\u00c0-\u00de\u00df-\u00ff\u0150\u0170\u0151\u0171]"
    @anyLetterR = /#{anyLetter}/m
    notLetter   = "[^A-Za-z0-9\u00c0-\u00de\u00df-\u00ff\u0150\u0170\u0151\u0171]"
    @notLetterR = /#{notLetter}/
    @startWord = "(^|#{notLetter})"
    @endWord = "(#{notLetter}|$)"
    @startWikiWord = "(^|[^~#{notLetter[2..-1]})"
    @wikiLink = "(?:" + upperLetter + "+" +
      lowerLetter + "+" +
      upperLetter +
      anyLetter + "*|" +
      upperLetter + "{2,}" +
      lowerLetter + "+)"
    @tiddlerAnyLink = ["(#{notLetter}#{@wikiLink})",
      "\\[\\[([^\\[\\]\\|]+)\\|([^\\[\\]\\|]+)\\]\\]",
      "\\[\\[([^\\]]+)\\]\\]", @urlPattern].join("|")
    @wikiChunk = "#{upperLetter}#{lowerLetter}+"
    @basicMorpheme = /#{@wikiChunk}/
    @format_tags = {
      "''" => "strong",
      "//" => "em",
      "__" => "u",
      "^^" => "sup",
      "~~" => "sub",
      "--" => "strike",
    }
    @format_match =
      @format_tags.keys.map{|s| Regexp.escape(s)}.join("|") + "(?!\\s|$)"
    @monospaced = {
      "{{{" => /^\{\{\{\n((?:^[^\n]*\n)+?)(^\}\}\}$\n?)/m,
      "//{{{" => /^\/\/\{\{\{\n\n*((?:^[^\n]*\n)+?)(\n*^\f*\/\/\}\}\}$\n?)/m,
      "/*{{{*/" => /\/\*\{\{\{\*\/\n*((?:^[^\n]*\n)+?)(\n*^\f*\/\*\}\}\}\*\/$\n?)/m,
      "<!--{{{-->" => /<!--\{\{\{-->\n*((?:^[^\n]*\n)+?)(\n*^\f*<!--\}\}\}-->$\n?)/m,
    }
    @monospaced_initial = "^(?:" +
      @monospaced.keys.map{|s| Regexp.escape(s)}.join("|") +
      ")\\n"
    @html_entities_match =
    "(?:(?:&#?[a-zA-Z0-9]{2,8};|.)(?:&#?(?:x0*(?:3[0-6][0-9a-fA-F]|1D[c-fC-F][0-9a-fA-F]|20[d-fD-F][0-9a-fA-F]|FE2[0-9a-fA-F])|0*(?:76[89]|7[7-9][0-9]|8[0-7][0-9]|761[6-9]|76[2-7][0-9]|84[0-3][0-9]|844[0-7]|6505[6-9]|6506[0-9]|6507[0-1]));)+|&#?[a-zA-Z0-9]{2,8};)"
    @output = /^<h3>\n(.*)\n<\/h3>\n<div>\n((?:.*\n)*?)<\/div> <!-- getOutput /
  end

  def self.refreshSplits(patches)
    prettySplits = {}
    recipes = []
    patches.split(/\n/).reject(&:empty?).each do |patch|
      if patch[-1] == "*"
        recipes << patch[0..-2] + @wikiChunk
      else
        lessPretty = patch.gsub(@notLetterR,"")
        lessPretty[0] = lessPretty[0].upcase
        prettySplits[lessPretty] = patch if patch != lessPretty
        recipes << lessPretty
      end
    end
    [prettySplits, /^(#{recipes.join('|')})/]
  end

  def self.scan_output(filename)
    File.read(filename).scan(@output)
  end

  class << self
    attr_reader :urlPattern, :wikiLink, :tiddlerAnyLink, :anyLetterR,
      :basicMorpheme, :format_tags, :format_match, :monospaced,
      :monospaced_initial, :html_entities_match, :upperStart,
      :startWord, :endWord, :startWikiWord
  end
end

Regex.initialize
