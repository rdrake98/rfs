# wiki.rb

require 'splitter'

class Wiki < Splitter
  def test_urls
    $t1 = true
    $a = []
    $aa = Struct.new(:tiddler, :url)
    tiddlers.each(&:output)
    puts $a.size
  end
end
