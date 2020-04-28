# wiki_with_tabs_sb.rb

require 'wiki_with_tabs'

class WikiWithTabsSB < WikiWithTabs
  attr_accessor :file_links
  def initialize(sb_file="s200428.013610p.js", wiki_file=nil)
    Dir.chdir("/Users/rd/Dropbox/_shared/link_data/backups")
    json = File.read(sb_file)[2..-1]
    sessions = JSON.parse(json)["sessions"]
    windows = sessions[0]["windows"]
    @file_links = windows.map {|window| FileLinksSB.new(window)}
    super(nil, wiki_file)
  end
end
