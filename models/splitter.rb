# splitter.rb

require 'tiddler'
require 'json'
require 'd' if $d ||= ARGV[-1] == "d" || ENV["dd"] == "d"
require 'dd' if $dd ||= ARGV[-1] == "dd" || ENV["dd"] == "dd"

class Splitter
  attr_accessor :code, :filename

  def parent_dir
    # kludge to support rff testing
    parent_type = @filename.split("/")[-1][0..2]
    filename = ENV[parent_type]
    (filename ? filename.split("/")[0..-2].join("/") : "unknown") + "/"
  end

  def initialize(filename=nil)
    @filename = filename
    @type = "dev" if @filename == Dir.dev
    @type = "fat" if @filename == Dir.fat
    @backup_area = "#{@filename.split("/")[0..-2].join("/")}/_backup" if @type
    @tiddler_hash = {}
    @tiddler_splits = {}
    @host = hostc
    return unless filename
    open(filename) do |file|
      @before = ""
      until (line = file.gets) =~ /<div id="storeArea">/
        @before << line
      end
      @before << line
      while (line = file.gets) =~ /<div title=.*/
        tiddler = Tiddler.from_file(self, file, line)
        self[tiddler.title] = tiddler
      end
      @mid = line
      until (line = file.gets) =~ /^<script id="jsArea"/
        @mid << line
      end
      @mid << line
      @code = ""
      until (line = file.gets) =~ /^<\/script>/
        @code << line
      end
      @after = line
      @after << line while (line = file.gets)
    end
  end

  def Splitter.fat
    new Dir.fat
  end

  def Splitter.dev
    new Dir.dev
  end

  def Splitter.name_(name, suffix="_")
    "#{name[0...-5]}#{suffix}.html"
  end

  def backup
    return unless @type
    command = "rsync -a #{@filename} #{@backup_area}/#{edition}"
    puts "backing up edition #{edition}"
    puts command
    `#{command}`
  end

  def commit_mods
    new_one = Splitter.name_(@filename)
    if File.file?(new_one)
      backup
      `mv #{new_one} #{@filename}`
    end
  end

  def count
    @tiddler_hash.count
  end

  def edition
    @before =~ /^var edition = "(.*)";$/
    $1 || @filename
  end

  def unsorted_tiddlers
    @tiddler_hash.values
  end

  def tiddlers
    unsorted_tiddlers.sort_by &:title
  end

  def titles
    tiddlers.map &:title
  end

  def titles_linked(title)
    self[title]&.titles_linked
  end

  def tiddlers_linked(title)
    self[title]&.tiddlers_linked || []
  end

  def titles_excluded
    titles_linked("MacrosNotTo") + titles_linked("AcceptableDifferences")
  end

  def testing_tiddlers
    tiddlers -
      tiddlers_linked("MacrosNotTo") - tiddlers_linked("AcceptableDifferences")
  end

  def normal_tiddlers
    tiddlers - [self["Search"], self["NewTiddlers"]]
  end

  def store_size
    unsorted_tiddlers.map(&:size).reduce(0, &:+)
  end

  def sizes
    [@before.size, store_size, @mid.size, @code.size, @after.size, count]
  end

  def [](title)
    @tiddler_hash[title]
  end

  def referent(link)
    @tiddler_hash[link] || @tiddler_splits[link.downcase]
  end

  def warmup_splits
    @prettySplits, @bespokeMorpheme =
      Regex.refreshSplits(self["NamePatches"]&.content || "") unless @prettySplits
  end

  def pretty(name)
    warmup_splits
    @prettySplits[name]
  end

  def splitName(name)
    self[name]&.splitname || splitNameFromPatches(name)
  end

  def splitNameFromPatches(name)
    warmup_splits
    split = []
    prettified = false
    i = 0
    while match = Regex.basicMorpheme.match(name, i)
      blockOfCaps = match.begin(0) > i ? name[i...match.begin(0)] : nil
      basicWord = match[0]
      bespokeMatch = @bespokeMorpheme.match(name[i..-1])
      if bespokeMatch
        bespokeWord = bespokeMatch[0]
        nextLetter = name[i + bespokeWord.size]
        q :bespokeWord, :nextLetter if $t2
        if nextLetter == nil || nextLetter =~ Regex.upperStart
          prettyWord = @prettySplits[bespokeWord]
          split << (prettyWord || bespokeWord)
          prettified = true
          i += bespokeWord.size
          q "@prettySplits", :prettyWord, :split, :i if $t2
        else
          bespokeMatch = nil
        end
      end
      if !bespokeMatch
        i += if blockOfCaps && blockOfCaps == "O"
          split << "O'#{basicWord}"
          basicWord.size + 1
        elsif blockOfCaps
          split << blockOfCaps
          blockOfCaps.size
        else
          split << basicWord
          basicWord.size
        end
      end
    end
    split << name[i..-1] if i < name.size
    prettified || name.size > 5 ? split.join(" ") : name
  end

  def []=(title, tiddler)
    @tiddler_hash[title] = tiddler
    @tiddler_splits[tiddler.splitdown] = tiddler
    @prettySplits = nil if tiddler.title == "NamePatches"
  end

  def change_tiddler(title, tiddler)
    delete(title) # because splitname may have changed
    self[title] = tiddler
  end

  def delete(title, noisy=false)
    tiddler = self[title]
    if tiddler
      puts "- tiddler found" if noisy
      @tiddler_hash.delete(title)
      puts "- split found" if @tiddler_splits.delete(tiddler.splitdown) && noisy
    else
      puts "- tiddler not found" if noisy
    end
  end

  def update_from(splitter, title, new_title=nil)
    source = splitter[title]
    if source
      if new_title
        target = self[new_title]
        if target
          target.content = source.content
        else
          create_new(new_title, source.content, splitName(new_title))
        end
      else
        change_tiddler(title, source)
      end
    end
  end

  def changes_file
    "#{changes_dir}/#{changes_file_}"
  end

  def changes_dir
    Dir.ww "_changes"
  end

  def changes_file_
    "#{@type}.json"
  end

  def shared_changes_file(host=@host)
    "/Users/rd/Dropbox/_changes/m#{host}_#{@type}.json"
  end

  def add_changes(json, shared=true)
    if @type
      text = json + "\n"
      File.write(changes_file, text)
      File.write(shared_changes_file, text) if shared
    end
  end

  def other_host
    @host == "p" ? "g" : "p"
  end

  def other_changes(from_self)
    commit_changes_file("before plusChanges* on startup", false)
    File.read(shared_changes_file(from_self ? @host : other_host))
  end

  def commit_changes_file(message, blank_shared=true)
    `cd #{changes_dir}; git add #{changes_file_}; git commit -m "#{message}"`
    File.write(shared_changes_file, "[]") if blank_shared
  end

  def add_tiddlers(json, loud=false)
    JSON.parse(json).each do |hash|
      # byebug if $dd
      title = hash["title"]
      if title
        delete(title) # because splitname may have changed
        self[title] = Tiddler.new(self, title, hash)
        puts title if loud
      else
        puts "#{hash} wants deleting" if loud
        delete(hash, true)
      end
    end
  end

  def create_new(title, content, split=nil)
    self[title] = Tiddler.new(self, title, content, split) unless self[title]
  end

  def compress(title, gap=1)
    ts = titles
    i1 = ts.find_index(title)
    i2 = i1 + gap
    content = tiddlers[i1..i2].map(&:content).join("--\n")
    tiddlers[i1].content = content
    ts[i1+1..i2].each {|t| delete(t)}
    write
    [i1, i2]
  end

  def contents
    @before + tiddlers.map(&:div_text).join + @mid + @code + @after
  end

  def sibling
    Splitter.new new_name("0")
  end

  def new_name(suffix="_")
    Splitter.name_ @filename, suffix
  end

  def external_link?(string)
    !self[string] && string =~ /#{Regex.urlPattern}|[.\/]/
  end

  def write(suffix="_", ed_end = "r")
    ed = edition
    ed =~ /^([a-z]+)\d+\.\d+([a-z]|).html$/
    ed = $1 + Time.now_dotted + ($2.size == 1 ? ed_end : '') + '.html'
    @before.gsub!(/^(var edition = ").*";$/, '\1' + ed + '";')
    bits = @filename.split("/")
    protect = bits[-2] == "_backup"
    filename = protect ? "/Users/rd/ww/_changed/#{bits[-1]}" : new_name(suffix)
    puts "writing edition #{edition} to #{filename}"
    File.write(filename, contents)
    protect ? filename : nil
  end

  def openc(suffix="_")
    `open #{new_name(suffix)}`
  end

  def read_file_edition
    open(@filename) do |file|
      until (line = file.gets) =~ /<div id="storeArea">/
        return $1 if line =~ /^var edition = "(.*)";$/
      end
    end
    nil
  end

  def check_file_edition(browser_edition, json=nil)
    return nil unless @type == "fat"
    file_edition = read_file_edition
    return nil if browser_edition == file_edition
    if json
      @browser_edition = browser_edition
      commit_changes_file("before fat file clash", false)
      add_changes(json)
      commit_changes_file("after fat file clash", false)
    end
    puts "clash between browser #{browser_edition} and file #{file_edition}"
    "#{file_edition},clash"
  end

  def save(browser_edition, json)
    clash = check_file_edition(browser_edition, json)
    return clash if clash
    commit_changes_file("before #{@type} saved") if @type
    add_changes(json)
    # qq :browser_edition, :edition if $dd
    if browser_edition == edition
      newFile = do_save(json)
      newFile ? [edition, newFile].join(",") : edition
    else
      nil
    end
  end

  def do_save(json=nil)
    add_tiddlers(json || File.read(changes_file), true)
    backup
    newFile = write("", @host)
    commit_changes_file("#{@type} #{json ? '' : 'force '}saved") if @type
    `cp -p #{@filename} $db/_shared/dev/m#{@host}` if @type == "dev"
    newFile
  end

  def cp_other_dev
    `cd #{parent_dir}; git add .; git commit -m "before cp_other_dev"`
    `cp -p $db/_shared/dev/m#{other_host}/dev5.html #{parent_dir}`
  end

  def inject_tests(testing)
    lines = @before.split("\n")
    lines[4] = testing ?
      "<script src='node_modules/qunitjs/qunit/qunit.js'></script>" :
      "<script type='text/javascript'>var QUnit = {test: function(){}}</script>"
    @before = lines.join_n
  end

  def update_code(testing=nil, suffix="")
    puts File.read(Dir.compiled "code.js").size
    puts "we can still inject tests into dev, for now"
    old_before = @before
    inject_tests(testing) unless testing == nil
    same = @before == old_before
    write(suffix) unless same
    !same
  end

  def update_scripts
    puts @mid.lines[-1]
    puts @after.lines[0..4]
  end

  def self.check_tiddlers(fixed=true)
    f = fixed ? fat : new("/Users/rd/rf/_milestones/f181211.212407g.html")
    puts f.tiddlers.select {|t| t.content =~ /\n\Z/}.size
    puts f.tiddlers.select {|t| t.content =~ / (\n|\Z)/}.size
    puts f.tiddlers.select {|t| t.created.size != 12}.size
    puts f.tiddlers.select {|t| t["modified"].size != 12}.size
    puts f.tiddlers.select {|t| t.modifier.nil?}.size
    puts f.tiddlers.select {|t| t.creator.nil?}.size
  end

  def self.show_numbers
    tiddlers = fat.tiddlers
    c = tiddlers.group_by(&:creator).map{|k,v|[k,v.size]}.sort_by{|a| -a[1]}
    m = tiddlers.group_by(&:modifier).map{|k,v|[k,v.size]}.sort_by{|a| -a[1]}
    cc = tiddlers.group_by(&:changecount).
      map{|k,v|[k.to_i,v.size]}.sort_by{|a| [-a[1],-a[0]]}
    [c, m, cc]
  end

  def shadow_titles
    @before.scan(/<div title="(.*)">\n/).map(&:first)
  end

  def config_titles
    (shadow_titles + self["OptionsPanel"].tiddler_links +
      %w[OpenTiddlers OpenTiddlersRaw RecentCreations DefaultTiddlers Search]
    ).uniq.sort
  end

  def expanded(titles)
    (titles + (titles << "MainMenu").map{|t| titles_linked(t)}.flatten).uniq
  end

  def write_tiny(hash, selected=[], file="empty", expand=false)
    tinys = {}
    hash.each do |key, content|
      title = key.to_s
      tinys[title] = Tiddler.new(self, title, content, self[title].splitname)
    end
    titles = config_titles + (expand ? expanded(selected) : selected)
    divs = titles.map {|t| (tinys[t] || self[t])&.div_text}.join
    tiny_wiki = @before + divs + @mid + @code.gsub('"75"', '"400"') + @after
    filename = Dir.tinys "#{file}.html"
    File.write(filename, tiny_wiki)
    [filename, titles.size, tiny_wiki.size]
  end

  def write_empty
    write_tiny(DefaultTiddlers: "GettingStarted", SiteTitle: "m")
  end

  def write_spec
    write_selected(
      %w[StopListInitial PreamblesInitial HashPreambles QPreambles], "spec")
  end

  def write_sb
    write_selected(%w[ExternalURLs], "sb")
  end

  def write_selected(titles, file, expand=false, title=file)
    title_links = titles.map {|t| self[t].to_link}
    configs = {DefaultTiddlers: title_links.join("\n"), SiteTitle: title}
    write_tiny(configs, titles, file, expand)
  end

  def write_sample(n, expand=false)
    write_selected(titles.sample(n), "sample", expand, "x")
  end

  def self.test_null(title)
    dev[title].test_null
  end
end
