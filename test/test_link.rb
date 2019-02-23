# test_link.rb

require 'minitest/autorun'
require 'splitter'

class TestLink < MiniTest::Test
  wiki_path = "#{ENV['data']}/dev_links.html"
  if ARGV[0] == "c"; `cp $dev #{wiki_path}`; end
  wiki = Splitter.new(wiki_path)
  name = 'TL01'
  t1 = wiki[name]
  t1a = wiki["#{name}A"]
  describe name do
    tests = t1a.content.split("-----")
    # qq :tests if $d
    tests.each do |test|
      lines = test.strip.lines
      search_text = lines[0].chomp
      result = lines[1].chomp
      # qq :lines, :search_text, :result if $d
      # binding.pry if $dd
      it search_text do
        assert_equal(result, t1.link(search_text))
      end
    end
  end
end
