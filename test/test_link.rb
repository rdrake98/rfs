# test_link.rb

require 'minitest/autorun'
require 'splitter'

class TestLink < MiniTest::Test
  wiki_path = "#{ENV['data']}/dev_links.html"
  if ARGV[0] == "c"
    `cp $dev #{wiki_path}`
  else
    wiki = Splitter.new(wiki_path)
    t1 = wiki['MainMenu']
    describe "all" do
      it "link 1" do
        assert_equal("", t1.content)
      end
    end
  end
end
