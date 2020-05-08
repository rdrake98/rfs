# splitter.rb

require 'tiddler'
require 'json'
require 'fileutils'
require 'd' if $d ||= ARGV[-1] == "d" || ENV["dd"] == "d"
require 'dd' if $dd ||= ARGV[-1] == "dd" || ENV["dd"] == "dd"

class Splitter
  attr_accessor :code

  def parent_dir
    # kludge to support rff testing
    parent_type = @filename.split("/")[-1][0..2]
    filename = ENV[parent_type]
    (filename ? filename.split("/")[0..-2].join("/") : "unknown") + "/"
  end

  def initialize(filename=nil, split=true)
    @filename = filename
    @type = "dev" if @filename == ENV["dev"]
    @type = "fat" if @filename == ENV["fat"]
    @backup_area = "#{@filename.split("/")[0..-2].join("/")}/_backup" if @type
    @split = split
    @tiddler_hash = {}
    @tiddler_splits = {}
    @store = ""
    @host = hostc
    return unless filename
    open(filename) do |file|
      @before = ""
      until (line = file.gets) =~ /<div id="storeArea">/
        @before << line
      end
      @before << line
      if split
        while (line = file.gets) =~ /<div title=.*/
          tiddler = Tiddler.from_file(self, file, line)
          self[tiddler.title] = tiddler
        end
      else
        while (line = file.gets) =~ /<div title=.*/
          @store << Tiddler.div_text(file, line)
        end
      end
      @mid = line
      until (line = file.gets) =~ /^<script id="jsArea" type="text\/javascript">/
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

  def Splitter.fat split=true
    new ENV["fat"], split
  end

  def Splitter.dev split=true
    new ENV["dev"], split
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
    backup
    `mv #{Splitter.name_(@filename)} #{@filename}`
  end

  def Splitter.test_same(filename2, small=true)
    splitter = Splitter.dev small
    sizes = splitter.sizes
    sizes2 = new(filename2).sizes
    same = sizes == sizes2
    puts same
    unless same
      puts
      puts sizes
      puts
      puts sizes2
    end
    same
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

  def store_size
    @split ? unsorted_tiddlers.map(&:size).reduce(0, &:+) : @store.size
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
    "#{ENV['ww']}/_changes"
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

  def other_changes(change_type)
    if change_type == "wiki"
      commit_changes_file("before plusChanges* on startup", false)
      File.read(shared_changes_file(other_host))
    else
      Dir.glob("../link_data/steps/fml/*.txt").map do |name|
        lines = File.read(name).lines
        {
          "title": lines[0].chomp,
          "modified": lines[1].chomp,
          "modifier": "RubyLinks",
          "text": lines[3..-1].join.gsub(/( +$|\s+\z)/, ""),
        }
      end.to_json
    end
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
        change_tiddler(title, Tiddler.new(self, title, hash))
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
    date_string = Time.now_str('.%H%M%S')
    ed =~ /^([a-z]+)\d+\.\d+([a-z]|).html$/
    ed = $1 + date_string + ($2.size == 1 ? ed_end : '') + '.html'
    @before.gsub!(/^(var edition = ").*";$/, '\1' + ed + '";')
    bits = @filename.split("/")
    protect = bits[-2] == "_backup"
    filename = protect ? "/Users/rd/ww/_changed/#{bits[-1]}" : new_name(suffix)
    puts "writing edition #{edition} to #{filename}"
    File.write(filename, contents)
    protect ? filename : nil
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
    return nil unless @type # need to check needs of non fat,dev wikis
    file_edition = read_file_edition
    return nil if browser_edition == file_edition
    if json && @type == "fat"
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
    if !@type || browser_edition == edition # check non fat,dev wikis
      newFile = do_save(json)
      newFile ? [edition, newFile].join(",") : edition # check non fat,dev wikis
    else
      nil
    end
  end

  def do_save(json=nil)
    add_tiddlers(json || File.read(changes_file), true)
    backup
    newFile = write("", @host)
    commit_changes_file("#{@type} #{json ? '' : 'force '}saved") if @type
    newFile
  end

  def inject_tests(testing)
    lines = @before.split("\n")
    lines[4] = testing ?
      "<script src='node_modules/qunitjs/qunit/qunit.js'></script>" :
      "<script type='text/javascript'>var QUnit = {test: function(){}}</script>"
    @before = lines.join_n
  end

  def update_code(testing=nil)
    puts "changing code for #{@filename}"
    puts @code.size
    new_code = File.read("#{ENV['compiled']}/code.js")
    same = @code == new_code
    @code = new_code
    puts same ? "code unchanged" : @code.size
    backup unless same
    old_before = @before
    inject_tests(testing) unless testing == nil
    same &&= @before == old_before
    write("") unless same
    !same
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

  def remove_shadow(title)
    @before.gsub!(/(<div title="(.*?)">.*?<\/div>\n)/m) do
      $2 == title ? "" : $1
    end
  end

  def config_titles
    (shadow_titles + self["OptionsPanel"].tiddler_links +
      %w[OpenTiddlers OpenTiddlersRaw RecentCreations DefaultTiddlers Search]
    ).uniq.sort
  end

  def expanded(titles)
    (titles + (titles << "MainMenu").map{|t| titles_linked(t)}.flatten).uniq
  end

  def write_tiny(hash, selected=[], file="empty", expand=false, censored=[], recent=[])
    tinys = {}
    hash.each do |key, content|
      title = key.to_s
      tinys[title] = Tiddler.new(self, title, content, self[title].splitname)
    end
    titles = (config_titles + (expand ? expanded(selected) : selected)).uniq
    titles = titles + recent - censored
    divs = titles.map {|t| (tinys[t] || self[t])&.div_text}.join
    tiny_wiki = @before + divs + @mid + @code.gsub('"75"', '"400"') + @after
    filename = "#{ENV['tinys']}/#{file}.html"
    File.write(filename, tiny_wiki)
    [filename, titles.size, tiny_wiki.size]
  end

  def write_empty
    write_tiny(DefaultTiddlers: "GettingStarted", SiteTitle: "m")
  end

  def write_spec
    write_selected(
      %w[StopListInitial PreamblesInitial HashPreambles QPreambles],
      "spec", false, "spec"
    )
  end

  def write_sb
    write_tiny({DefaultTiddlers: "OtherOptions", SiteTitle: "sb"}, [], "sb")
  end

  def write_selected(titles, file, expand=false, title="x")
    titles = titles.map(&:to_s)
    configs = {DefaultTiddlers: titles.join("\n"), SiteTitle: title}
    write_tiny(configs, titles, file, expand)
  end

  def write_for_jem(file)
    open_now = titles_linked("DefaultTiddlers")
    recent = tiddlers.sort_by(&:modified).map(&:title)[-40..-2]
    censored = titles_linked("CensorshipForJem") << "CensorshipForJem"
    write_tiny({}, open_now, file, true, censored, recent)
  end

  def write_sample(n, expand=false)
    write_selected(titles.sample(n), "sample", expand)
  end

  def self.test_null(title)
    dev[title].test_null
  end
end
