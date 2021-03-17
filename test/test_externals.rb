# test_externals.rb

require 'minitest/autorun'
require 'wiki_with_tabs'

class TestExternals < MiniTest::Test

  wiki_with_tabs = WikiWithTabs.new("s200428.013610p.js", "f200427.235854p")
  wiki = wiki_with_tabs.wiki

  describe "basics" do
    it "should select urls" do
      tiddler = wiki["NationalConvention"]
      assert_equal %w(
        http://www.google.com/search?q=National+Convention
        http://rogerpielkejr.blogspot.co.uk/2012/09/maestro.html
      ), tiddler.external_links.map {|e| e[1]}
    end

    it "should count urls" do
      tiddler = wiki["MainlyRuby20Jul15"]
      assert_equal 22, tiddler.external_links.size
      tiddler = wiki["MGTabs24Jul15H"]
      assert_equal 34, tiddler.external_links.size
    end
  end

  describe "reduction" do
    it "should reduce internally and from wiki sb" do
      assert_equal [148, 146, 141, 7], wiki_with_tabs.initial_reduce
      assert_equal [141, 103, 38], wiki_with_tabs.second_reduce
      assert_equal [103, 23, 7], wiki_with_tabs.qs_reduce
      assert_equal [96, 13, 3], wiki_with_tabs.hashes_reduce
    end
  end
end
