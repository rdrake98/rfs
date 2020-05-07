# wiki_with_tabs_sb.rb

require 'wiki_with_tabs'

class WikiWithTabsSB < WikiWithTabs
  def initialize(sb_file=nil, wiki_file=nil, spec=nil)
    Dir.chdir(ENV['tab_backups'])
    sb_file ||= Dir.glob("s*p.js").sort[-1]
    json = File.read(sb_file)[2..-1]
    windows = JSON.parse(json)["sessions"][0]["windows"]
    @file_links = windows.map {|window| FileLinksSB.new(window)}
    spec ||= "spec" unless wiki_file
    super(nil, wiki_file, spec)
  end

  def file_links
    @file_links.each(&:purge)
  end

  def show_tabs
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
