# wiki_with_tabs.rb

require 'splitter'
require 'link_analysis'
require 'file_links'

class WikiWithTabs
  attr_reader :wiki
  def initialize(branch, wiki_file, two_level=false)
    @branch = branch
    @wiki = wiki_file ?
      Splitter.new("#{ENV['data']}/#{wiki_file}.html") : Splitter.fat
    @spec = Splitter.new("#{ENV['data']}/spec.html")
    @two_level = two_level
  end

  def two_level
    @two_level && @two_level != :new_format
  end

  def new_format
    @two_level == :new_format
  end

  def WikiWithTabs.jan(wiki_file=nil)
    new("o160129", wiki_file)
  end

  def WikiWithTabs.today(wiki_file=nil)
    new("t#{Time.now_str}", wiki_file, :new_format)
  end

  include LinkAnalysis

  def do_reductions
    checkout("master")
    p initial_reduce
    p second_reduce
    p qs_reduce
    p hashes_reduce
  end

  def checkout(branch)
    `cd /Users/rd/ww/tabs; git reset --hard HEAD; git checkout #{branch}`
  end

  def day
    @branch[1..-1]
  end

  def tabs_dir
    "t#{day}"
  end

  def file_links
    pattern = "/Users/rd/ww/tabs/#{tabs_dir}/*#{two_level ? "/*" : ""}"
    Dir[pattern].map{|name| FileLinks.new(name, @two_level)}
  end

  def write_tiddlers
    pages = file_links
    pages = pages.select {|page| page.lines.size > 0}
    groups = pages.map(&:group).uniq
    groups.each do |group|
      pages.select {|page| page.group == group}.each_with_index do |page, i|
        page.number = sprintf('%02i',i+1)
      end
    end
    pages.sort_by!(&:tiddler_name).each do |page|
      name = page.tiddler_name
      @wiki["FOvByDay"].content += "\n#{name}"
      @wiki.create_new(name, page.content, "#{name[0..8]} #{name[9..11]}")
    end
    @wiki.write
    pages.size
  end

  def all_lines(tabs_pages)
    tabs_pages.map(&:lines).flatten
  end

  def spec_for(title)
    @spec[title].content.lines.map(&:chomp)
  end

  HASH_PREAMBLES = %w{
    http://climateaudit.org
    https://climateaudit.org
    https://wattsupwiththat.com
    https://judithcurry.com
    https://ipccreport.wordpress.com
    https://cliscep.com
    https://groups.google.com
  }

  def find_hashes_from_pages(tabs_pages)
    tiddlers = @wiki.tiddlers
    lines = all_lines(tabs_pages)
    hashes = lines.select &:pre_hash
    hashes.each_with_index do |line, i|
      url = line.url
      pre_hash = line.pre_hash
      line.wanted = HASH_PREAMBLES.any?{|preamble| url.start_with?(preamble)} ||
      (!tiddlers.any? do |tiddler|
        tiddler.external_links.any?{|link|line.pre_hash_matches?(link[1])}
      end && !hashes[0...i].any? {|line2| line2.pre_hash == pre_hash})
    end
    unwanted = hashes.reject &:wanted
    [lines.count, hashes.size, unwanted.size, *unwanted.map(&:url)]
  end

  def hashes_reduce
    tabs_pages = file_links
    stats = find_hashes_from_pages(tabs_pages)
    tabs_pages.each &:write
    stats[0..2]
  end

  Q_PREAMBLES = %w{
    https://www.google.co.uk/search
    https://www.google.com/search
    https://groups.google.com/forum/
    https://www.youtube.com/watch
    https://twitter.com/search
    https://www.biblegateway.com/passage/
    http://queue.acm.org/detail.cfm
    http://us11.campaign-archive2.com/
    http://us4.campaign-archive2.com/
    http://us4.campaign-archive1.com/
    http://www.eureferendum.com/blogview.aspx
    http://eureferendum.com/blogview.aspx
    https://news.ycombinator.com/item
    http://e360.yale.edu/content/feature.msp
  }

  def find_qs_from_pages(tabs_pages)
    tiddlers = @wiki.tiddlers
    lines = all_lines(tabs_pages)
    qs = lines.select &:preamble
    qs.each_with_index do |line, i|
      preamble = line.preamble
      line.wanted = Q_PREAMBLES.include?(preamble) ||
      (!tiddlers.any? do |tiddler|
        tiddler.external_links.any?{|link|line.preamble_matches?(link[1])}
      end && !qs[0...i].any? {|line2| line2.preamble == preamble})
    end
    unwanted = qs.reject &:wanted
    [lines.count, qs.size, unwanted.size, *unwanted.map(&:url)]
  end

  def qs_reduce
    tabs_pages = file_links
    stats = find_qs_from_pages(tabs_pages)
    tabs_pages.each &:write
    stats[0..2]
  end

  def second_reduce
    tiddlers = @wiki.tiddlers
    tabs_pages = file_links
    lines = all_lines(tabs_pages)
    lines.each do |line|
      url = line.url
      line.wanted = !tiddlers.any? do |tiddler|
        tiddler.external_links.any?{|link|link[1] == url}
      end
    end
    tabs_pages.each &:write
    [lines.size, lines.select(&:wanted).size, lines.reject(&:wanted).size]
  end

  def initial_reduce
    stop_list = %w{
      file:///Users/rd/Dropbox/fatword.html
      https://twitter.com/
      https://twitter.com/rdrake98
      https://twitter.com/following
      https://twitter.com/followers
      http://www.bishop-hill.net/
      http://climateaudit.org/
      https://climateaudit.org/
      http://www.dailymail.co.uk/home/index.html
      http://www.bbc.co.uk/news
      http://www.bbc.co.uk/sport/0/
      http://www.bbc.co.uk/iplayer
      http://www.jewishworldreview.com/cols/sowell1.asp
    }
    preambles = %w{
      about:
      http://localhost
      https://mail.google.com
      https://accounts.google.com
      http://www.premierleague.com
      http://www.bbc.co.uk/weather
      https://twitter.com/rdrake98/lists
      https://twitter.com/i/
      https://twitter.com/login?
      https://twitter.com/?
      http://ruby-doc.org
      https://www.movegb.com
    }
    tabs_pages = file_links
    lines = all_lines(tabs_pages)
    stats = [lines.size]
    lines.each do |line|
      url = line.url
      line.wanted = !stop_list.include?(url) && !url.start_with?(*preambles)
    end
    wanted_lines = lines.select &:wanted
    stats << wanted_lines.size
    wanted_lines.each_with_index do |line, i|
      url = line.url
      wanted_lines[i+1..-1].each {|line2| line2.wanted &&= line2.url != url}
    end
    tabs_pages.each &:write
    # lines.each do |line|
    #   puts line.content if line.url.start_with?("https://www.movegb.com")
    # end
    stats << lines.select(&:wanted).size << lines.reject(&:wanted).size
  end
end
