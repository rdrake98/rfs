# test_externals.rb

require 'minitest/autorun'
require 'wiki_with_tabs_sb'

class TestExternals < MiniTest::Test

  wiki_with_tabs = WikiWithTabs.jan("f160117.041732g")
  wiki_with_tabs_sb = WikiWithTabsSB.new("s200428.013610p.js", "f200427.235854p")
  wiki = wiki_with_tabs.wiki

  describe "basics" do
    it "should select urls" do
      tiddler = wiki["FO19Jul15"]
      assert_equal %w(
        https://archive.org/stream/byte-magazine-1981-08/1981_08_BYTE_06-08_Smalltalk#page/n15/mode/2up
        https://www.statwing.com/demos/dev-survey#workspaces/2496
      ), tiddler.external_links.map {|e| e[1]}
    end

    it "should count urls" do
      tiddler = wiki["MainlyRuby20Jul15"]
      assert_equal 30, tiddler.external_links.size
      tiddler = wiki["MGTabs24Jul15H"]
      assert_equal 35, tiddler.external_links.size
    end
  end

  describe "reduction" do
    it "should reduce internally and from wiki" do
      wiki_with_tabs.from_original do
        assert_equal [1052, 995, 966, 86], wiki_with_tabs.initial_reduce
        assert_equal [966, 722, 244], wiki_with_tabs.second_reduce
        assert_equal [722, 120, 9], wiki_with_tabs.qs_reduce
        assert_equal [713, 61, 13], wiki_with_tabs.hashes_reduce
      end
    end

    it "should reduce internally and from wiki sb" do
      assert_equal [148, 146, 141, 7], wiki_with_tabs_sb.initial_reduce
      assert_equal [141, 103, 38], wiki_with_tabs_sb.second_reduce
      assert_equal [103, 23, 7], wiki_with_tabs_sb.qs_reduce
      assert_equal [96, 13, 3], wiki_with_tabs_sb.hashes_reduce
    end
  end
end
