# wiki_with_tabs_sb.rb

require 'wiki_with_tabs'

class WikiWithTabsSB < WikiWithTabs
  def initialize(sb_file, wiki_file=nil)
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
    []
    # pattern = "/Users/rd/ww/tabs/#{tabs_dir}/*#{two_level ? "/*" : ""}"
    # Dir[pattern].map{|name| FileLinks.new(name, @two_level)}
  end
end
