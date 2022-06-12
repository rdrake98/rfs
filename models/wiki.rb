# wiki.rb

require 'splitter'

class Wiki < Splitter
  def test_urls
    $t1 = true
    $a = []
    $aa = Struct.new(:tiddler, :url)
    self["WanyURLs"].output
    puts $a
  end
end
