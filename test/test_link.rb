# test_link.rb

require 'minitest/autorun'
require 'splitter'

module Minitest::Assertions
  def assert_has_line(content, line)
    assert_includes(content.split("\n"), line)
  end
end

class TestLink < MiniTest::Test
  wiki_path = "#{ENV['data']}/dev_links.html"
  if ARGV[0] == "c"; `cp $dev #{wiki_path}`; end
  wiki = Splitter.new(wiki_path)
  name = 'TL01'
  t1 = wiki[name]
  t1a = wiki["#{name}A"]
  describe name do
    tests = t1a.content.split("----\n")
    tests.each do |test|
      search_text, result = test.split("\n")
      # binding.pry if $dd
      it search_text do
        assert_has_line(t1.link(search_text), result)
      end
    end
  end
end
