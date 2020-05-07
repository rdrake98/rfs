# wiki_with_tabs_sb.rb

require 'wiki_with_tabs'

class WikiWithTabsSB < WikiWithTabs
  def initialize(name=nil, wiki_file=nil, spec=nil)
    @file_links = []
    Dir.chdir(ENV['tab_backups'])
    name ||= Dir.glob("s*p.js").sort[-1]
    tiddler_name = "S#{name[1..6]}#{name[8..9]}#{name[14]}N"
    windows = JSON.parse(File.read(name)[2..-1])["sessions"][0]["windows"]
    @file_links += windows.map {|window| FileLinksSB.new(window, tiddler_name)}
    spec ||= "spec" unless wiki_file
    super(nil, wiki_file, false, spec)
  end

  def file_links
    @file_links.each(&:purge)
  end

  def show_final_tabs
    file = @wiki.write_sb[0]
    tabs_wiki = Splitter.new(file)
    initial_reduce
    second_reduce
    qs_reduce
    hashes_reduce
    puts file_links.size
    wins = file_links.filter {|win| win.content.size > 0}
    puts wins.size
    tiddlers = []
    wins.each_with_index do |win, i|
      name = win.name + "%02i" % (i+1)
      tabs_wiki.create_new(name, win.content)
      tiddlers << name
    end
    tabs_wiki["DefaultTiddlers"].content = tiddlers.join("\n")
    tabs_wiki.write("")
    `open #{file}`
    [tabs_wiki.tiddlers.size, tabs_wiki.contents.size]
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
