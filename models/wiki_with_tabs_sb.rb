# wiki_with_tabs_sb.rb

require 'wiki_with_tabs'

class WikiWithTabsSB < WikiWithTabs
  def initialize(name=nil, wiki_file=nil, spec=nil)
    @file_links = []
    Dir.chdir(ENV['tab_backups'])
    start = name.is_a?(Integer) ? name : -1
    name = nil unless start == -1
    names = name ? [name] : Dir.glob("s*.js").sort[start..-1]
    names.each do |name|
      tiddler = "S#{name[1..6]}#{name[14]}N#{name[8..9]}"
      windows = JSON.parse(File.read(name)[2..-1])["sessions"][0]["windows"]
      @file_links += windows.map {|window| FileLinksSB.new(window, tiddler)}
    end
    spec ||= "spec" unless wiki_file
    super(nil, wiki_file, false, spec)
  end

  def file_links
    @file_links.each(&:purge)
  end

  def show_final_tabs
    file = @wiki.write_sb[0]
    tabs_wiki = Splitter.new(file)
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
        if prev[0..-4] == win.name
          lines_already = tabs_wiki[prev].content.lines.size
          if lines + lines_already < 44
            tabs_wiki[prev].content += "--\n" + content
            skipped = true
          end
        end
      end
      unless skipped
        name = win.name + "%03i" % (i+1)
        split = name[0..7] + " " + name[8..-1]
        tabs_wiki.create_new(name, content, split)
        tiddlers << name
      end
    end
    tabs_wiki["DefaultTiddlers"].content = tiddlers.join("\n")
    tabs_wiki.write("")
    `open #{file}`
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
