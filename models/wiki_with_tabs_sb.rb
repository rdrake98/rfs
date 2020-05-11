# wiki_with_tabs_sb.rb

require 'wiki_with_tabs'

class WikiWithTabsSB < WikiWithTabs
  def initialize(name=nil, wiki_file=nil, spec=nil)
    spec ||= "spec" unless wiki_file
    super(nil, wiki_file, false, spec)
    last_backup = @spec["LastBackup"]&.content&.chomp # nil in old tests
    copy_backups
    all_names = read_all_names
    names = name.is_a?(Integer) ?
      all_names[name..-1] :
      name ?
        [name] :
        all_names[all_names.find_index(last_backup) + 1..-1]
    @file_links = []
    names.each do |name|
      tiddler = "S#{name[1..6]}N#{name[8..9]}#{name[14]}"
      windows = JSON.parse(File.read(name)[2..-1])["sessions"][0]["windows"]
      @file_links += windows.map {|window| FileLinksSB.new(window, tiddler)}
    end
  end

  def s6(name, i); name[i..i+1] + name[i+3..i+4] + name[i+6..i+7]; end

  def copy_backups
    Dir.chdir('/Users/rd/Downloads')
    to = "~/rf/link_data/copied"
    Dir.glob("session_buddy_backup_*.json").sort.each do |name|
      `cp -p #{name} #{to}/s#{s6(name, 23)}.#{s6(name, 32)}#{hostc}.js`
    end
    puts `rsync -t --out-format=%n%L #{to}/* $tab_backups/`
  end

  def read_all_names
    Dir.chdir(ENV['tab_backups'])
    Dir.glob("s*.js").sort
  end

  def commit_mods(suffix=1)
    last_backup = read_all_names[-1]
    if @spec["LastBackup"].content != last_backup
      dir="backups/b#{DateTime.now.strftime("%y%m%d")}#{"%02d"%suffix}"
      puts `cd $tinys; rsync -t --out-format=%n%L s* #{dir}`
      @spec["LastBackup"].content = last_backup
      @spec.write("")
      puts "LastBackup in #{@spec.filename} is now #{last_backup}"
      puts "Deleting..."
      puts `cd $tinys; rm -v sb_.html`
    else
      puts "LastBackup in #{@spec.filename} is already #{last_backup}"
      puts "So not doing any committing"
    end
  end

  def WikiWithTabsSB.copy_to_fat
    fat = Splitter.fat
    puts fat.tiddlers.size
    Dir.chdir(ENV['tinys'])
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
        if prev[0..-5] + prev[-1] == win.name
          lines_already = tabs_wiki[prev].content.lines.size
          if lines + lines_already < 44
            tabs_wiki[prev].content += "--\n" + content
            skipped = true
          end
        end
      end
      unless skipped
        name = win.name[0..-2] + "%03i" % (i+1) + win.name[-1]
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
