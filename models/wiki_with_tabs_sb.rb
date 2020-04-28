# wiki_with_tabs_sb.rb

require 'wiki_with_tabs'

class WikiWithTabsSB < WikiWithTabs
  def initialize(sb_file="s200428.013610p.js", wiki_file=nil)
    @sb_file = sb_file
    super(nil, wiki_file)
  end

  def show_reductions
    p initial_reduce
    # p second_reduce
    # p qs_reduce
    # p hashes_reduce
  end

  def file_links
    Dir.chdir("/Users/rd/Dropbox/_shared/link_data/backups")
    json = File.read(@sb_file)[2..-1]
    sessions = JSON.parse(json)["sessions"]
    windows = sessions[0]["windows"]
    windows.map {|window| FileLinksSB.new(window)}
    # pattern = "/Users/rd/ww/tabs/#{tabs_dir}/*#{two_level ? "/*" : ""}"
    # Dir[pattern].map{|name| FileLinks.new(name, @two_level)}
  end
end
