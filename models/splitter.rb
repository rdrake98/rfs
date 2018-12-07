# splitter.rb

require 'tiddler'
require 'tiddler_links'
require 'tiddler_list'
require 'json'
require 'd' if $d = ARGV[0] == "d"
require 'dd' if $dd = ARGV[0] == "dd"

class Splitter
  def self.shadow?(name); TiddlerList.shadows.include?(name); end

  attr_accessor :code

  def initialize(filename=nil, split=true)
    @filename = filename
    @wiki_type = "dev" if @filename == ENV["dev"]
    @wiki_type = "fat" if @filename == ENV["fat"]
    @backup_area = "#{@filename.split("/")[0..-2].join("/")}/_backup" if @wiki_type
    @backup_area = "/Volumes/SH1/_backup" if mp? && @wiki_type == "fat"
    @fat_backup_area = "/Users/rd/rf/_backup" if @wiki_type == "fat"
    # was "/Users/rd/ww/_b2/#{@wiki_type}/_backup"
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
    dev false, split
  end

  def Splitter.dev small=true, split=true
    new name(small), split
  end

  def Splitter.dev_alt
    new "/Users/rd/ww/emptys/dev_alt.html", true
  end

  def Splitter.name(small)
    ENV[small ? "dev" : "fat"]
  end

  def Splitter.name_(name, suffix="_")
    "#{name[0...-5]}#{suffix}.html"
  end

  def backup
    return unless @wiki_type
    command = "rsync -a #{@filename} #{@backup_area}/#{edition}"
    puts "backing up edition #{edition}"
    puts command
    `rsync -a #{@filename} #{@fat_backup_area}/#{edition}` if @fat_backup_area
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
    $1
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

  def split(name)
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
    "#{ENV['data']}/#{changes_file_}"
  end

  def changes_file_
    "_changes/#{@wiki_type}.json"
  end

  def commit_changes_file(message)
    `cd $data; git add #{changes_file_}; git commit -m "#{message}"`
  end

  def update_from_json
    return unless @wiki_type
    add_tiddlers(File.read(changes_file))
    write
  end

  def add_tiddlers(json)
    JSON.parse(json).each do |hash|
      byebug if $dd
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
    add_tiddlers(json)
  end

  def save(browser_edition, json)
    dropbox_edition = nil
    open(@filename) do |file|
      until (line = file.gets) =~ /<div id="storeArea">/
        if line =~ /^var edition = "(.*)";$/
          dropbox_edition = $1
          break
        end
      end
    end
    if browser_edition == dropbox_edition
      server_edition = edition
      if browser_edition == server_edition
        commit_changes_file("before #{@wiki_type} saved") if @wiki_type
        add_changes(json)
        backup
        newFile = write("", @host)
        commit_changes_file("#{@wiki_type} saved") if @wiki_type
        newFile ? [edition, newFile].join(",") : edition
      else
        clash(browser_edition, server_edition, "server")
      end
    else
      clash(browser_edition, dropbox_edition, "dropbox")
    end
  end

  def clash(browser_edition, other_edition, type)
    puts "clash between browser #{browser_edition} and #{type} #{other_edition}"
    "#{other_edition},clash"
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
end
