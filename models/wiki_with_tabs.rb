# wiki_with_tabs.rb

require 'splitter'
require 'file_links'

class WikiWithTabs
  attr_reader :wiki
  def initialize(file)
    @wiki = file ? Splitter.new(Dir.data "#{file}.html") : Splitter.fat
    @spec = Splitter.new("#{file ? Dir.data("spec") : Dir.tinys(spec)}.html")
    @stop_list = spec_for("StopListInitial")
    @preambles = spec_for("PreamblesInitial")
    @hash_preambles = spec_for("HashPreambles")
    @q_preambles = spec_for("QPreambles")
  end

  def spec_for(title)
    @spec[title].content.lines.map(&:chomp)
  end

  def all_lines(tabs_pages)
    tabs_pages.map(&:lines).flatten
  end

  def find_hashes_from_pages(tabs_pages)
    tiddlers = @wiki.tiddlers
    lines = all_lines(tabs_pages)
    hashes = lines.select &:pre_hash
    hashes.each_with_index do |line, i|
      url = line.url
      pre_hash = line.pre_hash
      line.wanted = @hash_preambles.any?{|preamble| url.start_with?(preamble)} ||
      (!tiddlers.any? do |tiddler|
        tiddler.external_links.any?{|link|line.pre_hash_matches?(link[1])}
      end && !hashes[0...i].any? {|line2| line2.pre_hash == pre_hash})
    end
    unwanted = hashes.reject &:wanted
    [lines.count, hashes.size, unwanted.size, *unwanted.map(&:url)]
  end

  def hashes_reduce
    stats = find_hashes_from_pages(file_links)[0..2]
  end

  def find_qs_from_pages(tabs_pages)
    tiddlers = @wiki.tiddlers
    lines = all_lines(tabs_pages)
    qs = lines.select &:preamble
    qs.each_with_index do |line, i|
      preamble = line.preamble
      line.wanted = @q_preambles.include?(preamble) ||
      (!tiddlers.any? do |tiddler|
        tiddler.external_links.any?{|link|line.preamble_matches?(link[1])}
      end && !qs[0...i].any? {|line2| line2.preamble == preamble})
    end
    unwanted = qs.reject &:wanted
    [lines.count, qs.size, unwanted.size, *unwanted.map(&:url)]
  end

  def qs_reduce
    find_qs_from_pages(file_links)[0..2]
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
    [lines.size, lines.select(&:wanted).size, lines.reject(&:wanted).size]
  end

  def initial_reduce
    tabs_pages = file_links
    lines = all_lines(tabs_pages)
    stats = [lines.size]
    lines.each do |line|
      url = line.url
      line.wanted = !@stop_list.include?(url) && !url.start_with?(*@preambles)
    end
    wanted_lines = lines.select &:wanted
    stats << wanted_lines.size
    wanted_lines.each_with_index do |line, i|
      url = line.url
      wanted_lines[i+1..-1].each {|line2| line2.wanted &&= line2.url != url}
    end
    stats << lines.select(&:wanted).size << lines.reject(&:wanted).size
  end
end
