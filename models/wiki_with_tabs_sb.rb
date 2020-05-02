# wiki_with_tabs_sb.rb

require 'wiki_with_tabs'

class WikiWithTabsSB < WikiWithTabs
  def initialize(sb_file=nil, wiki_file=nil)
    Dir.chdir(ENV['tab_backups'])
    sb_file ||= Dir.glob("s*p.js").sort[-1]
    json = File.read(sb_file)[2..-1]
    windows = JSON.parse(json)["sessions"][0]["windows"]
    @file_links = windows.map {|window| FileLinksSB.new(window)}
    super(nil, wiki_file)
  end

  def file_links
    @file_links.each(&:purge)
  end

  def show_tabs
    sb = @wiki.write_sb
    `open #{sb[0]}`
    sb
  end
end
