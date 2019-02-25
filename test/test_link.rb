# test_link.rb

require 'minitest/autorun'
require 'splitter'

module Minitest::Assertions
  def assert_has_line(content, line)
    assert_includes(content.split("\n"), line)
  end
end

class TestLink < MiniTest::Test
  wiki_path = "#{ENV['HOME']}/rf/_data/dev_for_link_tests.html"
  if ARGV[0] == "c"; `cp $dev #{wiki_path}`; end
  wiki = Splitter.new(wiki_path)
  %w[TL01 TL02 TL03].each do |name|
    describe name do
      tests = wiki["#{name}A"].content.split("----\n")
      tests.each do |test|
        search_text, result = test.split("\n")
        # binding.pry if $dd
        it search_text do
          assert_has_line(wiki[name].link(search_text, false, false), result)
        end
      end
    end
  end
end
