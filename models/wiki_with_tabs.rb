# wiki_with_tabs.rb

require 'splitter'
require 'file_links'

class WikiWithTabs
  attr_reader :wiki
  def initialize(name=nil, file=nil)
    @wiki = file ? Splitter.new(Dir.data "#{file}.html") : Splitter.fat
    @spec = Splitter.new("#{file ? Dir.data : Dir.tinys}/spec.html")
    @stop_list = spec_for("StopListInitial")
    @preambles = spec_for("PreamblesInitial")
    @hash_preambles = spec_for("HashPreambles")
    @q_preambles = spec_for("QPreambles")
    last_backup = @spec["LastBackup"]&.content&.chomp # nil in old tests
    self.class.copy_backups
    all_names = self.class.read_all_names
    names = name ?
      [name] :
      all_names[all_names.index(last_backup) + 1..-1]
    @file_links = []
    names.each do |name|
      tiddler = "S#{name[1..6]}N#{name[8..11]}"
      windows = JSON.parse(File.read(name)[2..-1])["sessions"][0]["windows"]
      @file_links += windows.map {|window| FileLinks.new(window, tiddler)}
    end
  end

  def self.write_filters(dir)
    file = dir + "/spec.html"
    return unless File.file? file
    wiki = Splitter.new(file)
    Dir.cd :rfs, "tab_filters"
    time = %w(
      StopListInitial
      PreamblesInitial
      HashPreambles
      QPreambles
    ).map do |name|
      tiddler = wiki[name]
      tiddler.write_simple
      tiddler.modified
    end.max.dotted
    puts "#{wiki.tiddlers.size} #{time} #{dir}"
    added = `git add -v .`
    unless added.empty?
      wiki["LastBackup"].write_simple
      bash = "cd $rfs; git add tab_filters; git commit -m '#{time} recent'".taps
      puts `#{bash}`
    else
      puts "no new filters to commit"
    end
    Dir.chdir(dir)
    wiki["LastBackup"].write_simple
    `rm spec.html`
  end

  def self.cleanup
    Dir.cd(:tinys, 'backups').glob("*").each do |dir|
      Dir.cd(dir).glob("sb*").each do |sb_file|
        sb = Splitter.new(sb_file)
        titles = sb.titles.filter {|title| title =~ /^(S2|WIN|Windows)/}
        titles.each {|title| sb[title].write_simple}
        `rm #{sb_file}`
      end
      write_filters(Dir.pwd)
      Dir.chdir('..')
    end
  end

  def self.s6(name, i); name[i..i+1] + name[i+3..i+4] + name[i+6..i+7]; end
  def self.short_name(name); "s#{s6(name, 23)}.#{s6(name, 32)}#{hostc}.js"; end
  Copied = Dir.home + "/rf/link_data/copied/"

  def self.copy_backups
    Dir.cd(Downloads).glob("session_buddy_backup_*.json").each do |name|
      `cp -p #{name} #{Copied}#{short_name(name)}`
    end
    `rsync -t --out-format=%n%L #{Copied}* $tab_backups/`.taps
  end

  def self.unpeel
    name = Dir.cd(Downloads).glob("session_buddy_backup_*.json")[-1].taps
    copied_local = Copied + (short_name = short_name(name))
    if File.file? copied_local
      `rm #{name}`
      puts `rm -v #{copied_local}`
      `cd $tab_backups; mv -v #{short_name} _rejected`
    else
      "#{copied_local} doesn't exist so no unpeel"
    end.taps
  end

  def self.read_all_names
    Dir.cd(:tab_backups).glob("s*.js")
  end

  def self.commit_mods(force=false)
    last_backup = read_all_names[-1]
    spec = Splitter.new(Dir.tinys "spec.html")
    if force || spec["LastBackup"].content != last_backup
      ymd = Time.new.ymd
      dir = "backups/b#{ymd}%02d" %
        (Dir.cd(:tinys, 'backups').glob("b#{ymd}*")[-1]&.[](-2..-1).to_i + 1)
      puts `cd $tinys; rsync -t --out-format=%n%L sb.html spec.html #{dir}`
      spec["LastBackup"].content = last_backup
      spec.write("")
      message = "LastBackup in #{spec.filename} is now #{last_backup}"
      puts message
      cleanup # slow and dirty
      Splitter.fat.commit_mods
      "commit_mods done: " + message
    else
      puts "LastBackup in #{spec.filename} is already #{last_backup}"
      puts "Not doing any committing"
      "Not doing any committing"
    end
  end

  def self.copy_to_fat
    fat = Splitter.fat
    puts fat.tiddlers.size
    sb = Splitter.new(Dir.tinys "sb.html")
    titles = sb.titles
    puts titles.size
    titles = titles.filter {|title| title =~ /^S2/}
    puts titles.size
    titles = titles.each {|title| fat.update_from(sb, title)}
    time = Time.now
    name = time.strftime "S%YM%m"
    if fat[name]
      fat[name].content += "\n" + titles.join("\n")
    else
      fat.create_new(name, titles.join("\n"), time.strftime("S%Y M%m"))
      fat["S2020Elinks"].content += "\n" + name
    end
    puts fat.tiddlers.size
    fat.write
    fat.openc
  end

  def file_links
    @file_links.each(&:purge)
  end

  def show_final_tabs
    tabs_wiki = Splitter.new(@wiki.write_sb[0])
    tiddlers = []
    file_links.each_with_index do |win, i|
      name = "WIN%02i" % (i+1)
      tabs_wiki.create_new(name, win.content)
      tiddlers << name
    end
    tabs_wiki.create_new("Windows", tiddlers.join("\n"))

    p initial_reduce
    p second_reduce
    p qs_reduce
    p hashes_reduce
    wins = file_links.filter {|win| win.content.size > 0}
    tiddlers = ["ExternalURLs"]
    wins.each_with_index do |win, i|
      skipped = false
      content = win.content
      lines = content.lines.size
      if tiddlers.size > 0 && lines < 40
        prev = tiddlers[-1]
        if prev[0..-3] == win.name
          lines_already = tabs_wiki[prev].content.lines.size
          if lines + lines_already < 44
            tabs_wiki[prev].content += "--\n" + content
            skipped = true
          end
        end
      end
      unless skipped
        name = win.name + "%02i" % (i+1)
        split = name[0..6] + " " + name[7..-1]
        tabs_wiki.create_new(name, content, split)
        tiddlers << name
      end
    end
    tabs_wiki["DefaultTiddlers"].content = tiddlers.join("\n")
    tabs_wiki.write("")
    tabs_wiki.openc("")
    [file_links.size, wins.size, tiddlers.size,
      tabs_wiki.tiddlers.size, tabs_wiki.contents.size]
  end

  def spec_for(title)
    @spec[title].content.lines.map(&:chomp)
  end

  def all_lines(tabs_pages)
    tabs_pages.map(&:lines).flatten
  end

  def find_hashes_from_pages(tabs_pages)
    tiddlers = @wiki.tiddlers
    lines = all_lines(tabs_pages)
    hashes = lines.select &:pre_hash
    hashes.each_with_index do |line, i|
      url = line.url
      pre_hash = line.pre_hash
      line.wanted = @hash_preambles.any?{|preamble| url.start_with?(preamble)} ||
      (!tiddlers.any? do |tiddler|
        tiddler.external_links.any?{|link|line.pre_hash_matches?(link[1])}
      end && !hashes[0...i].any? {|line2| line2.pre_hash == pre_hash})
    end
    unwanted = hashes.reject &:wanted
    [lines.count, hashes.size, unwanted.size, *unwanted.map(&:url)]
  end

  def hashes_reduce
    stats = find_hashes_from_pages(file_links)[0..2]
  end

  def find_qs_from_pages(tabs_pages)
    tiddlers = @wiki.tiddlers
    lines = all_lines(tabs_pages)
    qs = lines.select &:preamble
    qs.each_with_index do |line, i|
      preamble = line.preamble
      line.wanted = @q_preambles.include?(preamble) ||
      (!tiddlers.any? do |tiddler|
        tiddler.external_links.any?{|link|line.preamble_matches?(link[1])}
      end && !qs[0...i].any? {|line2| line2.preamble == preamble})
    end
    unwanted = qs.reject &:wanted
    [lines.count, qs.size, unwanted.size, *unwanted.map(&:url)]
  end

  def qs_reduce
    find_qs_from_pages(file_links)[0..2]
  end

  def second_reduce
    tiddlers = @wiki.tiddlers
    tabs_pages = file_links
    lines = all_lines(tabs_pages)
    lines.each do |line|
      url = line.url
      line.wanted = !tiddlers.any? do |tiddler|
        tiddler.external_links.any?{|link|link[1] == url}
      end
    end
    [lines.size, lines.select(&:wanted).size, lines.reject(&:wanted).size]
  end

  def initial_reduce
    tabs_pages = file_links
    lines = all_lines(tabs_pages)
    stats = [lines.size]
    lines.each do |line|
      url = line.url
      line.wanted = !@stop_list.include?(url) && !url.start_with?(*@preambles)
    end
    wanted_lines = lines.select &:wanted
    stats << wanted_lines.size
    wanted_lines.each_with_index do |line, i|
      url = line.url
      wanted_lines[i+1..-1].each {|line2| line2.wanted &&= line2.url != url}
    end
    stats << lines.select(&:wanted).size << lines.reject(&:wanted).size
  end
end
