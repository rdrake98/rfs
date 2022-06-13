# wiki.rb

require 'splitter'
require 'benchmark'

class Wiki < Splitter
  def test_urls
    $t1 = true
    $aa = Struct.new(:tiddler, :url)
    re = /^(http|https):\/\//
    $a = []
    tiddlers.each(&:output)
    puts $a.size
    $a.select!{ |s| s.url =~ re }
    puts $a.size
    $b = []
    tiddlers.each(&:external_links)
    puts $b.size
    $b.select!{ |s| s.url =~ re }
    puts $b.size
    ag = $a.group_by &:tiddler
    puts ag.size
    bg = $b.group_by &:tiddler
    puts bg.size
    diffa = ag.keys - bg.keys
    puts diffa.size
    diffa[0..4].each do |t|
      puts t
      ag[t].each{ |s| puts "  " + s.url }
    end
    diffb = bg.keys - ag.keys
    puts diffb.size
    diffb.each do |t|
      puts t
      bg[t].each{ |s| puts "  " + s.url }
    end
    ag.each do |t, a|
      as = a.size
      b = bg[t]
      bs = b.size
      if as != bs
        puts
        puts t, as, bs
        puts b.map(&:url) - a.map(&:url)
      end
    end
    [ag, bg, diffa, diffb]

    # [1] pry(main)> require 'wiki'; fat = Wiki.fat;
    # [2] pry(main)> ag, bg, diffa, diffb = fat.test_urls;
    # 125351
    # 122516
    # 124420
    # 122517
    # 35343
    # 35344
    # 0
    # 1
    # TerribleItalicBug
    #   http://script.aculo.us)//
  end

  def check_benchmark
    $t1 = true
    $aa = Struct.new(:tiddler, :url)
    re = /^(http|https):\/\//
    $b = []
    Benchmark.realtime do
      puts Benchmark.realtime {tiddlers.each(&:external_links)}
      puts $b.size
      puts Benchmark.realtime {$b.select!{ |s| s.url =~ re }}
      puts $b.size
    end.taps
  end
end
