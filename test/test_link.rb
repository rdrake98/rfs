# test_link.rb

require 'minitest/autorun'
require 'splitter'

module Minitest::Assertions
  def assert_has_line(content, line)
    assert_includes(content.split("\n"), line)
  end
end

class TestLink < MiniTest::Test
  wiki_path = "#{Dir.data}/dev_.html"
  if ARGV[0] == "c"; `cp $dev #{wiki_path}`; end
  wiki = Splitter.new(wiki_path)
  wiki.titles.grep(/^TL\d+$/).each do |name|
    describe name do
      tests = wiki["#{name}A"].content.split("----\n")
      tests.each do |test|
        search_text, result = test.split("\n")
        it search_text do
          assert_has_line(wiki[name].link(search_text, false, false), result)
        end
      end
    end
  end

  describe "WikiText" do
    it "blanking" do
      content = "one {{{two}}} three"
      wt = WikiText.new content
      blanked = wt.blank("{{{", "}}}")
      assert_equal(blanked, "one           three")
      assert_equal(content, wt.content)
    end
  end
end
