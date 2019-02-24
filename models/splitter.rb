# splitter.rb

require 'tiddler'
require 'tiddler_links'
require 'tiddler_list'
require 'json'
require 'fileutils'
require 'd' if $d ||= ARGV[-1] == "d" || ENV["dd"] == "d"
require 'dd' if $dd ||= ARGV[-1] == "dd" || ENV["dd"] == "dd"

class Splitter
  def self.shadow?(name); TiddlerList.shadows.include?(name); end

  attr_accessor :code

  def initialize(filename=nil, split=true)
    @filename = filename
    @wiki_type = "dev" if @filename == ENV["dev"]
    @wiki_type = "fat" if @filename == ENV["fat"]
    @backup_area = "#{@filename.split("/")[0..-2].join("/")}/_backup" if @wiki_type
    @split = split
    @tiddler_hash = {}
    @tiddler_splits = {}
    @store = ""
    @host = mp? ? "p" : "g"
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
    return unless @wiki_type
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

  def macros_not_to
    tiddlers_linked("MacrosNotTo")
  end

  def acceptable_differences
    tiddlers_linked("AcceptableDifferences")
  end

  def testing_tiddlers
    tiddlers - macros_not_to - acceptable_differences
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

  def update_from(splitter, title)
    tiddler = splitter[title]
    change_tiddler(title, tiddler) if tiddler
  end

  def changes_file
    "#{changes_dir}/#{changes_file_}"
  end

  def changes_dir
    "#{ENV['ww']}/_changes"
  end

  def changes_file_
    "#{@wiki_type}.json"
  end

  def commit_changes_file(message)
    `cd #{changes_dir}; git add #{changes_file_}; git commit -m "#{message}"`
  end

  def add_tiddlers(json)
    JSON.parse(json).each do |hash|
      # byebug if $dd
      title = hash["title"]
      if title
        change_tiddler(title, Tiddler.new(self, title, hash))
        puts title
      else
        puts "#{hash} wants deleting"
        delete(hash, true)
      end
    end
  end

  def create_new(title, content, split=nil)
    self[title] = Tiddler.new(self, title, content, split) unless self[title]
  end

  def reduce_externals(mg_list, mp_lists)
    tiddler = self[mg_list]
    external_links = TiddlerLinks.new(tiddler)
    puts external_links.urls.size
    mp_lists.each do |title|
      urls = TiddlerLinks.new(self[title]).urls
      puts "- #{urls.size}"
      external_links.reduce(urls)
      puts external_links.urls.size
    end
    tiddler.content = external_links.content
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
    !self[string] && string =~ /#{Regex.urlPattern}|[.\/#\\]/
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

  def add_changes(json)
    File.write(changes_file, json + "\n") if @wiki_type
  end

  def read_file_edition
    open(@filename) do |file|
      until (line = file.gets) =~ /<div id="storeArea">/
        return $1 if line =~ /^var edition = "(.*)";$/
      end
    end
    nil
  end

  def save(browser_edition, json)
    file_edition = read_file_edition
    if browser_edition == file_edition
      commit_changes_file("before #{@wiki_type} saved") if @wiki_type
      add_changes(json)
      if browser_edition == edition
        newFile = do_save(json)
        newFile ? [edition, newFile].join(",") : edition
      else
        nil
      end
    else
      if @wiki_type == "fat"
        @browser_edition = browser_edition
        commit_changes_file("before fat file clash")
        add_changes(json)
        commit_changes_file("after fat file clash")
      end
      puts "clash between browser #{browser_edition} and file #{file_edition}"
      "#{file_edition},clash"
    end
  end

  def do_save(json=nil)
    add_tiddlers(json || File.read(changes_file))
    backup
    newFile = write("", @host)
    commit_changes_file(
      "#{@wiki_type} #{json ? '' : 'force '}saved") if @wiki_type
    newFile
  end

  def inject_tests(testing)
    lines = @before.split("\n")
    lines[4] = testing ?
      "<script src='node_modules/qunitjs/qunit/qunit.js'></script>" :
      "<script type='text/javascript'>var QUnit = {test: function(){}}</script>"
    @before = lines.join_n
  end

  def cstring(source)
    File.read("#{ENV['compiled']}/#{source}.js")
  end

  def update_code(testing=false)
    puts "changing code for #{@filename}"
    puts @code.size
    @code = cstring("code")
    puts @code.size
    inject_tests(testing) unless testing == :none
    write("")
  end

  def self.dir
    "/Users/rd/rf/tiddlers3"
  end

  def self.dir2
    dir[-1] == "2" ? dir[0...-1] : dir + "2"
  end

  def self.mkdir(dir1=dir)
    FileUtils.remove_dir(dir1) if Dir.exist?(dir1)
    Dir.mkdir(dir1)
    Dir.chdir(dir1)
    `gin`
  end

  def write_tiddlers(time=nil, noisy=true, message=edition)
    byebug if $dd
    dir = Dir.pwd
    Dir.chdir(Splitter.dir)
    FileUtils.rm Dir.glob('*.txt')
    puts "writing #{message}" if noisy
    tiddlers.each(&:write)
    puts "committing #{message}" if noisy
    if time
      git_time = time.to_s[0..-7]
      pre = "git add .; GIT_COMMITTER_DATE="
      `#{pre}"#{git_time}" git commit -m #{message} --date "#{git_time}"`
    else
      `gcaa #{message}`
    end
    Dir.chdir(dir)
  end

  def sync
    Splitter.mkdir(Splitter.dir2)
    root_wiki = Splitter.new("#{@backup_area}/#{@browser_edition}")
    root_wiki.write_tiddlers
    write_tiddlers
    root_wiki.add_tiddlers(File.read(changes_file))
    `git checkout HEAD^; git checkout -b clash`
    root_wiki.write_tiddlers(nil, true, "unsaved changes")
  end

  def content_from(lines, dedup=false)
    lines = lines[7..-1]
    if dedup
      size = lines.size
      lines = lines&.uniq
      puts "dedup saved #{size - lines.size} lines"
    end
    lines&.join("\n").to_s
  end

  def changed_from_dir
    changed = {}
    Dir.chdir(Splitter.dir)
    Dir.glob("*.txt", File::FNM_DOTMATCH).each do |f|
      # should check hex before doing gsub
      title = f.split(".")[0..-3].join(".").gsub("*", "/")
      lines = File.read(f).split("\n")
      content = self[title]&.content
      file_content = content_from(lines)
      if content != file_content &&
        content != file_content + "\n" &&
        content != file_content + "\n\n"
        changed[title] = lines
      end
    end
    changed
  end

  def merge
    # no changes to splitname or deletions, first time around
    added = []
    changed = []
    # hard-coded the first time
    merged = %w[DevDec18 FatwordSync FromMonday]
    changed_from_dir.each do |title, lines|
      unless title == "Search"
        puts title, lines[5]
        tiddler = self[title]
        if tiddler
          changed << tiddler
          dedup = title == "DefaultTiddlers"
          time = merged.include?(title) ? nil : lines[1]
          tiddler.merge_content(content_from(lines, dedup), time, lines[5])
        else
          t = self["MainMenu"] # kludge
          hash = {
            "text" => content_from(lines),
            "creator" => "RubyMerge",
            "modifier" => "RubyMerge",
            "created" => t.jsontime(lines[2]),
            "modified" => t.jsontime(lines[1]),
            "fields" => {"splitname" => lines[0], "changecount" => lines[5]}
          }
          tiddler = Tiddler.new(self, title, hash)
          self[title] = tiddler
          added << tiddler
        end
      end
    end
    content = (changed + added).map(&:wiki_link).join("\n")
    create_new("1210Merge", content, "1210 Merge")
    write
    [changed.size, added.size]
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
    (shadow_titles +
      self["OptionsPanel"].content.split(/\W+/) +
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
    titles = (config_titles + (expand ? expanded(selected) : selected)).uniq
    divs = titles.map {|t| (tinys[t] || self[t])&.div_text}.join
    tiny_wiki = @before + divs + @mid + @code + @after
    File.write("/Users/rd/rf/tinys/#{file}.html", tiny_wiki)
    [titles.size, tiny_wiki.size]
  end

  def write_empty
    write_tiny(DefaultTiddlers: "GettingStarted", SiteTitle: "m")
  end

  def write_selected(titles, file, expand=false)
    titles = titles.map(&:to_s)
    configs = {DefaultTiddlers: titles.join("\n"), SiteTitle: "x"}
    write_tiny(configs, titles, file, expand)
  end

  def write_sample(n, expand=false)
    write_selected(titles.sample(n), "sample", expand)
  end
end
