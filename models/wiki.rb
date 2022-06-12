# wiki.rb

require 'splitter'
require 'benchmark'

class Wiki < Splitter
  def test_urls
    $t1 = true
    $a = []
    $aa = Struct.new(:tiddler, :url)
    puts Benchmark.measure {tiddlers.each(&:output)}
    puts Benchmark.measure {tiddlers.each(&:output)}
    puts Benchmark.measure {tiddlers.each(&:external_links)}
    puts Benchmark.measure {tiddlers.each(&:external_links)}
    puts $a.size
  end
end
