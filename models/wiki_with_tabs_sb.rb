# wiki_with_tabs_sb.rb

require 'wiki_with_tabs'

class WikiWithTabsSB < WikiWithTabs
  def initialize(name=nil, wiki_file=nil, spec=nil)
    super(nil, wiki_file, false, wiki_file ? spec : spec || "spec")
    last_backup = @spec["LastBackup"]&.content&.chomp # nil in old tests
    self.class.copy_backups
    all_names = self.class.read_all_names
    names = name == 0 ?
      [all_names[-1]] :
      name ?
        [name] :
        all_names[all_names.index(last_backup) + 1..-1]
    @file_links = []
    names.each do |name|
      tiddler = "S#{name[1..6]}N#{name[8..11]}#{name[14]}"
      windows = JSON.parse(File.read(name)[2..-1])["sessions"][0]["windows"]
      @file_links += windows.map {|window| FileLinksSB.new(window, tiddler)}
    end
  end

  def self.write_filters(dir)
    file = dir + "/spec.html"
    return unless File.file? file
    wiki = Splitter.new(file)
    Dir.chdir(:rfs)
    Dir.chdir("tab_filters")
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
      bash = "git add tab_filters; git commit -m '#{time} recently'"
      puts bash
      `#{bash}`
    else
      puts "no new filters to commit"
    end
    Dir.chdir(dir)
    wiki["LastBackup"].write_simple
    `rm spec.html`
  end

  def self.cleanup
    Dir.chdir(:tinys)
    Dir.chdir('backups')
    dirs = Dir.glob "*"
    dirs.each do |dir|
      Dir.chdir(dir)
      Dir.glob("sb*").each do |sb_file|
        sb = Splitter.new(sb_file)
        titles = sb.titles.filter {|title| title =~ /^S2/}
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
    Dir.chdir('/Users/rd/Downloads')
    Dir.glob("session_buddy_backup_*.json").each do |name|
      `cp -p #{name} #{Copied}#{short_name(name)}`
    end
    `rsync -t --out-format=%n%L #{Copied}* $tab_backups/`.tap{|s| puts s}
  end

  def self.unpeel
    Dir.chdir('/Users/rd/Downloads')
    name = Dir.glob("session_buddy_backup_*.json")[-1]
    puts name
    copied_local = Copied + (short_name = short_name(name))
    if File.file? copied_local
      `rm #{name}`
      puts `rm -v #{copied_local}`
      `cd $tab_backups; mv -v #{short_name} _rejected`
    else
      "#{copied_local} doesn't exist so no unpeel"
    end.tap{|s| puts s}
  end

  def self.read_all_names
    Dir.chdir(:tab_backups)
    Dir.glob("s*.js").sort
  end

  def self.commit_mods
    last_backup = read_all_names[-1]
    spec = Splitter.new("#{Dir.tinys}/spec.html")
    if spec["LastBackup"].content != last_backup
      Dir.chdir(:tinys)
      Dir.chdir('backups')
      ymd = Time.new.ymd
      suffix = Dir.glob("b#{ymd}*")[-1]&.[](-2..-1).to_i + 1
      dir = "backups/b#{ymd}%02d" % suffix
      puts `cd $tinys; rsync -t --out-format=%n%L s* #{dir}`
      spec["LastBackup"].content = last_backup
      spec.write("")
      message = "LastBackup in #{spec.filename} is now #{last_backup}"
      puts message
      cleanup # quick and dirty  -> slower execution
      Splitter.fat.commit_mods;
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
    Dir.chdir(:tinys)
    sb_file = Dir.glob("sb*.html").sort[-1]
    puts "Using #{sb_file}"
    sb = Splitter.new(sb_file)
    titles = sb.titles
    puts titles.size
    titles = titles.filter {|title| title =~ /^S2/}
    puts titles.size
    titles = titles.each {|title| fat.update_from(sb, title)}
    fat["S2020M05a"].content += "\n" + titles.join("\n")
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
    tiddlers = []
    wins.each_with_index do |win, i|
      skipped = false
      content = win.content
      lines = content.lines.size
      if tiddlers.size > 0 && lines < 40
        prev = tiddlers[-1]
        if prev[0..-4] + prev[-1] == win.name
          lines_already = tabs_wiki[prev].content.lines.size
          if lines + lines_already < 44
            tabs_wiki[prev].content += "--\n" + content
            skipped = true
          end
        end
      end
      unless skipped
        name = win.name[0..-2] + "%02i" % (i+1) + win.name[-1]
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

  def show_tabs_being_reduced
    file = @wiki.write_sb[0]
    tabs_wiki = Splitter.new(file)
    file_links.each do |win|
      tabs_wiki.create_new("W0D#{win.id}", win.content)
    end
    initial_reduce
    file_links.each do |win|
      tabs_wiki.create_new("W1D#{win.id}", win.content)
    end
    second_reduce
    file_links.each do |win|
      tabs_wiki.create_new("W2D#{win.id}", win.content)
    end
    qs_reduce
    file_links.each do |win|
      tabs_wiki.create_new("W3D#{win.id}", win.content)
    end
    hashes_reduce
    file_links.each do |win|
      tabs_wiki.create_new("W4D#{win.id}", win.content)
    end

    tabs_wiki.write("")
    `open #{file}`
    [tabs_wiki.tiddlers.size, tabs_wiki.contents.size]
  end
end
