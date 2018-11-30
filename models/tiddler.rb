# tiddler.rb

require 'base'
require 'wikifier'
require 'regex'
require 'time'

class Tiddler
  attr_reader :header, :title, :content

  def initialize(wiki, title, content, header_or_split=nil)
    @wiki = wiki
    if title
      @title = title
      @header = "<div>"
      self.title = title
      if content.is_a?(String)
        self.content = content
        self.creator = modifier
        self.created = modified
        self.splitname = header_or_split || title
      else
        @content = content["text"]
        self.creator = content["creator"]
        self.modifier = content["modifier"]
        self.created = jsontime(content["created"])
        self.modified = jsontime(content["modified"])
        self.splitname = content["fields"]["splitname"]
        self.changecount = content["fields"]["changecount"]
      end
    else
      @content = content
      @header = header_or_split
      @title = self[:title]
    end
  end

  def self.from_file(wiki, file, line)
    div_text(file, line) =~ /^(<div.*?>)\n<pre>(.*)<\/pre>\n<\/div>$/m
    Tiddler.new(wiki, nil, CGI::unescapeHTML($2), $1)
  end

  def self.div_text(file, line)
    div_text = ""
    begin
      div_text << line
      line = file.gets
    end until line =~ /<\/div>/
    div_text << line
  end

  def div_text
    "#{@header}\n<pre>#{CGI::h2 @content}</pre>\n</div>\n"
  end

  def jsontime(string)
    string && strftime(Time.parse(string))
  end

  def strftime(datetime)
    datetime.strftime "%Y%m%d%H%M"
  end

  def content= content
    return if @content == content
    @content = content
    return if basic
    self.modifier = "RubyTuesday"
    self.modified = strftime(Time.now.utc)
    self.changecount = changecount.to_i + 1
  end

  def [] attribute
    @header =~ /#{attribute}="([^"]+)"/ &&
      CGI::unescapeHTML($1).gsub(/\\s/m,"\\")
  end

  def self.attribute_phrase attribute, value
    "#{attribute}=\"#{CGI::h2 value.to_s}\""
  end

  def []= attribute, value
    regex = /#{attribute}="[^"]+"/
    phrase = self.class.attribute_phrase attribute, value
    @header =~ regex ?
      @header.sub!(regex, phrase) :
      @header = "#{@header[0..-2]} #{phrase}>"
  end

  def method_missing(name, *args)
    args.size == 0 ?
      self[name] :
      name[-1] == "=" && !args[0].nil? ? self[name[0..-2]] = args[0] : nil
  end

  def wiki_link
    "[[#{splitname}]]"
  end

  def created
    @created ||= self["created"]
  end

  def creation_order
    @creation_order ||= created + @title
  end

  def modified
    string = self["modified"]
    time_from(string || created)
  end

  def time_from(s)
    Time.new(s[0..3],s[4..5],s[6..7],s[8..9],s[10..11])
  end

  def size
    div_text.size
  end

  def changed?
    div_text != @div_text
  end

  def splitdown
    splitname.downcase
  end

  def parse_external_links
    juice = @content.gsub(/(<html>.*?<\/html>|{{{.*?}}}|""".*?""")/m, " ")
    re = /(\[\[(.*?)\]\]|\[[<>]?img\[.*?\]\]|((http|https|file|ftp):\/\/\S*)(?=\s))/
    " #{juice} ".scan(re).map do |a|
      if a[1]
        pair = a[1].split("|")
        pair = [pair[0],pair[1..-1].join("|")] if pair.size > 2
        pair.size==2 && pair[1].match(/(\.|\/)/) &&
          !pair[1].start_with?("txmt:") && pair
      elsif a[2]
        url = a[2].match(/(.*[^.,;:'")>?|!\]*&=])[.,;:'")>?|!\]*&=]*/) && $1
        url = url.split('"')[0]
        !url.start_with?("chrome:") && [url, url]
      else
        nil
      end
    end.select(&:itself) # removing false, not nil
  end

  def external_links
    @external_links ||= parse_external_links
  end

  def self.parse_tiddler_links(text, wiki=Splitter.new)
    regex = /#{Regex.tiddlerAnyLink}/m
    match = regex.match(" " + text)
    links = []
    # q :text
    while (match)
      # q :match
      if match[1]
        links << match[1][1..-1] unless match[1][0] == "~"
      elsif match[4]
        links << match[4]
      elsif match[2]
        links << match[3] unless wiki.external_link?(match[3])
      end
      match = regex.match(text, match.offset(0)[1] - 1)
    end
    links.uniq
  end

  def basic_content
    @content.gsub(/\/%((?:.|\n)*?)%\//,"").
      gsub(/\{{3}((?:.|\n)*?)\}{3}/,"").
      gsub(/"""((?:.|\n)*?)"""/,"").
      gsub(/<nowiki\>((?:.|\n)*?)<\/nowiki\>/,"").
      gsub(/<html\>((?:.|\n)*?)<\/html\>/,"").
      gsub(/<script((?:.|\n)*?)<\/script\>/,"")
  end

  def search_text
    @content.gsub(/\/%((?:.|\n)*?)%\//,"").
      gsub(/\{{3}((?:.|\n)*?)\}{3}/," #{$1} ")
  end

  def tiddler_links
    @tiddler_links ||= Tiddler.parse_tiddler_links(basic_content, @wiki)
  end

  def tiddlers_linked
    tiddler_links.map{|s|@wiki.referent(s)}.compact.uniq
  end

  def titles_linked
    tiddlers_linked.map(&:title)
  end

  def self.wikify(text, wiki=Splitter.new)
    Wikifier.new(text, wiki).wikify
  end

  def self.output(text, wiki)
    wikify(text, wiki).gsub("<br>", "<br>\n") + "\n"
  end

  def output
    $t = @title if $t1 || $d
    @output ||= Tiddler.output(@content, @wiki)
  end

  def Tiddler.html(title, output)
    "<h3>\n#{title}\n</h3>\n<div>\n#{output}\n</div> <!-- getOutput #{title} -->\n"
  end

  def html
    Tiddler.html(title, output)
  end
end