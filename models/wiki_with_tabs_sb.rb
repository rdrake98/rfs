# wiki_with_tabs_sb.rb

require 'wiki_with_tabs'

class WikiWithTabsSB < WikiWithTabs
  def initialize(name=nil, wiki_file=nil, spec=nil)
    spec ||= "spec" unless wiki_file
    super(nil, wiki_file, false, spec)
    last_backup = @spec["LastBackup"]&.content&.chomp
    Dir.chdir(ENV['tab_backups'])
    all_names = Dir.glob("s*.js").sort
    names = name.is_a?(Integer) ?
      all_names[name..-1] :
      name ?
        [name] :
        all_names[all_names.find_index(last_backup + ".js") + 1..-1]
    @file_links = []
    names.each do |name|
      tiddler = "S#{name[1..6]}N#{name[8..9]}#{name[14]}"
      windows = JSON.parse(File.read(name)[2..-1])["sessions"][0]["windows"]
      @file_links += windows.map {|window| FileLinksSB.new(window, tiddler)}
    end
  end

  def WikiWithTabsSB.copy_202005_to_fat
    fat = Splitter.fat
    puts fat.tiddlers.size
    sb = Splitter.new("#{ENV['tinys']}/s200507/sb_edit.html")
    puts sb.tiddlers.size
    fat.update_from(sb, "TiddlersByMonth", "S2020M05Top")
    sb["CompressedTiddlers"].titles_linked.each do |title|
      fat.update_from(sb, title)
    end
    sb["TiddlersByMonth"].titles_linked.each do |title|
      fat.update_from(sb, title)
    end
    puts fat.tiddlers.size
    fat.write
  end

  def WikiWithTabsSB.copy_to_fat
    fat = Splitter.fat
    puts fat.tiddlers.size
    sb = Splitter.new("#{ENV['tinys']}/sb_.html")
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
