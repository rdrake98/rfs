# tiddler.rb

require 'base'
require 'wikifier_null'
require 'wiki_text'
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
        self.created = self["modified"]
        self.splitname = header_or_split || wiki.splitName(title)
      else
        @content = content["text"]
        self.creator = content["creator"]
        self.modifier = content["modifier"]
        self.created = jsontime(content["created"])
        self.modified = jsontime(content["modified"])
        self.splitname = content["fields"]["splitname"]
        self.changecount = content["fields"]["changecount"]
        medited = content["fields"]["medited"]
        self.medited = jsontime(medited) if medited
      end
    else
      @content = content
      @header = header_or_split
      @title = self[:title]
    end
  end

  def self.from_file(wiki, file, line)
    div_text(file, line) =~ /^(<div.*?>)\n<pre>(.*)<\/pre>\n<\/div>$/m
    new(wiki, nil, CGI::unescapeHTML($2), $1)
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

  def update_content content, minor_edit=false
    return if @content == content
    @content = content
    if minor_edit
      self.medited = strftime(Time.now.utc)
    else
      self.modifier = "RubyTuesday"
      self.modified = strftime(Time.now.utc)
      self.changecount = changecount.to_i + 1
    end
  end

  def content= content
    update_content content
  end

  def [] attribute
    @header =~ /#{attribute}="([^"]+)"/ &&
      CGI::unescapeHTML($1).gsub(/\\s/m,"\\")
  end

  def self.attribute_phrase attribute, value, escaped=true
    s = value.to_s
    s = escaped ? CGI::h2(s) : CGI::h4(s)
    "#{attribute}=\"#{s}\""
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

  def to_link
    WikiText.isWikiLink(@title) ? @title : lazy_link
  end

  def lazy_link
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

  def medited
    string = self["medited"]
    string && time_from(string)
  end

  def time_from(s)
    Time.utc(s[0..3],s[4..5],s[6..7],s[8..9],s[10..11])
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
    WikiText.new(@content).basic_content
  end

  def tiddler_links
    @tiddler_links ||= Tiddler.parse_tiddler_links(basic_content, @wiki)
  end

  def link(search_text, target, unlink, overlink)
    WikiText.new(@content).link(@wiki, search_text, target, unlink, overlink)
  end

  def to_h
    fields = {
      "splitname" => splitname,
      "changecount" => changecount,
    }
    (d = self["medited"]) && fields["medited"] = d
    {
      "title" => title,
      "text" => content,
      "creator" => creator,
      "modifier" => modifier,
      "modified" => modified,
      "created" => time_from(created),
      "fields" => fields,
    }
  end

  def bulk_change
    specs = @content.lines[0].chomp.split(", ")
    return "[]" if specs.size != 3
    from, to, scope = specs
    re = /^\"\"\"(.*)\"\"\"$/
    from = from =~ re ? $1 : from
    to = to =~ re ? $1 : to
    targets = scope == "all" ?
      @wiki.normal_tiddlers - [self] :
      @wiki[scope].tiddlers_linked
    edits = targets.select do |t|
      old_content = t.content
      new_content = old_content.sub(from, to)
      t.update_content(new_content, true)
      old_content != new_content
    end
    if edits.size > 0
      time = edits[0].medited.to_minute
      links = edits.map(&:to_link).join(" - ")
      self.content = @content + "\n#{time} #{links}"
      ([to_h] + edits.map(&:to_h)).to_json
    else
      "[]"
    end
  end

  def bulk_change_test(content)
    specs = content.split(", ")
    return "[]" if specs.size != 3
    from, to, scope = specs
    re = /^\"\"\"(.*)\"\"\"$/
    from = from =~ re ? $1 : from
    to = to =~ re ? $1 : to
    if from[0] == ","
      from = /(\W)#{from[1..-1]}/
      to = "\\1#{to}"
    end
    targets = scope == "all" ?
      @wiki.normal_tiddlers - [self] :
      @wiki[scope].tiddlers_linked
    edits = targets.select do |t|
      old_content = t.content
      new_content = old_content.sub(from, to)
      old_content != new_content
    end
    [edits.size, from, to]
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
    # puts @output if $dd
  end

  def Tiddler.html(title, output)
    "<h3>\n#{title}\n</h3>\n<div>\n#{output}\n</div> <!-- getOutput #{title} -->\n"
  end

  def html
    Tiddler.html(title, output)
  end

  def filename
    "#{title.gsub("/", "*")}.#{hex}.txt"
  end

  def hex
    bin = 1
    tot = 0
    title.each_char do |c|
      tot += bin if c != c.downcase || c == "/"
      bin *= 2
    end
    tot.to_s(36)
  end

  def write
    # byebug if $dd && filename == "F1706mgN01.3l.txt"
    readable = []
    readable << splitname
    readable << modified
    readable << time_from(created)
    readable << modifier
    readable << creator
    readable << changecount
    readable << ""
    readable << content
    readable = readable.join("\n")
    File.write(filename, readable + "\n")
    readable
  end

  def write_simple
    readable = []
    readable << splitname
    readable << modified
    readable << ""
    readable << content
    readable = readable.join("\n")
    File.write("#{title}.txt", readable + "\n")
    readable
  end

  def googleWords(title)
    words = @wiki.splitName(title)
    "[[#{words}|http://www.google.com/search?q=#{words.gsub(' ', '+')}]]"
  end

  def write_mini(googling)
    readable = []
    readable << title
    readable << modified
    readable << ""
    if googling
      readable << "Try googling for #{googleWords(title)}"
      readable << ""
    end
    readable << content
    readable = readable.join("\n")
    File.write(filename, readable + "\n")
  end

  def test_null
    result = WikifierNull.new(@content, @wiki).wikify
    puts @content.size
    puts result.size
    p "   " + @content.gsub('"""',"'''").gsub("\n"," ")
    result
  end
end
