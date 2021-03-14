# link_analysis.rb

module LinkAnalysis

  def file_sizes
    file_links.map{|f|[f.filename,f.urls.size]}
  end

  def external_links
    return @external_links if @external_links
    @external_links = []
    @wiki.tiddlers.each{|t| @external_links +=
      t.external_links.map{|l| [l[1], t.title, l[0]]}}
    file_external_links.each {|f| @external_links +=
      f.lines.map{|l| [l.url, " #{f.filename.split('/')[-1][0..-5]}", l.text]}}
    @external_links.sort!
  end

  def show_qs
    qs = find_qs_from_pages(file_links)
    p qs[0..2]
    puts qs[3..-1]
  end

  def show_hashes
    hashes = find_hashes_from_pages(file_links)
    p hashes[0..2]
    puts hashes[3..-1]
  end

  def show_reductions
    p initial_reduce
    p second_reduce
    p qs_reduce
    p hashes_reduce
  end
end
