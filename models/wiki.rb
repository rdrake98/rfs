# wiki.rb

require 'splitter'
require 'benchmark'

class Wiki < Splitter
  def Wiki.quicker_edition
    my_fat = nil
    timeb("slow") {puts (my_fat = fat).edition}
    timeb("quicker") {puts fat_edition}
    timeb("quickest") {puts my_fat.edition}
  end

  def check_benchmark
    $t1 = true
    $aa = Struct.new(:tiddler, :url)
    $b = []
    timeb "total" do
      timeb("elinks") {tiddlers.each(&:external_links)}
    end
  end

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
end
