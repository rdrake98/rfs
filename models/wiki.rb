# wiki.rb

require 'splitter'
require 'benchmark'

class Wiki < Splitter
  def test_urls
    $t1 = true
    $aa = Struct.new(:tiddler, :url)
    $a = []
    tiddlers.each(&:output)
    puts $a.size
    $b = []
    tiddlers.each(&:external_links)
    puts $b.size
    ag = $a.group_by &:tiddler;
    puts ag.size
    bg = $b.group_by &:tiddler;
    puts bg.size
    [ag, bg]
    # ag, bg = fat.test_urls;
    # Xbox has the same
    # diff = ag.keys - bg.keys and the opposite
  end
end
