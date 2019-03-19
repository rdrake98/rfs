# test_tiddler_links.rb

require 'minitest/autorun'
require 'splitter'

class TestTiddlerLinks < MiniTest::Test

  type = ARGV[0] || "dev"
  if type == "few"
    describe "links" do
      it "~WikiWord etc" do
        assert_equal(
          ["one two", "AB1", "WikiWord", "APIs"],
          Tiddler.parse_tiddler_links(
            "[[one two]] AB1 WikiWord ~IThink ~NotOne\nAPIs\n"
          )
        )
      end
      it "WikiWord after ]]" do
        assert_equal(
          ["Twitter", "OGP13"],
          Tiddler.parse_tiddler_links(
            "[[Twitter]] [[Results for #|https://twitter.com/]]OGP13 have been amazing"
          )
        )
      end
      it "dangling [[" do
        assert_equal(
          ["BackboneJs", "ElasticSearch", "Faye", "MassageLinks\nTweetFilter - [[Grab to jpg"],
          Tiddler.parse_tiddler_links(<<~END
            Bit of BackboneJs, ElasticSearch
            [[Faye]]
            [[MassageLinks
            TweetFilter - [[Grab to jpg]]
          END
          )
        )
      end
    end
  else
    if ARGV[1]
      puts "please seed from javascript"
      exit
    end
    wiki = Splitter.new("#{ENV['data']}/#{type}_.html")
    lines = File.read("#{ENV['data']}/#{type}_links.txt").split("\n")
    tiddlers = []
    tiddler_links = nil
    lines.each do |line|
      line.start_with?("  ") ?
        tiddler_links[1] << line[2..-1].gsub("\\n","\n") :
        tiddlers << tiddler_links = [line, []]
    end

    describe "all" do
      tiddlers.each do |tiddler, links|
        it "links for '#{tiddler}'" do
          assert_equal links, wiki[tiddler].tiddler_links
        end
      end
    end
  end
end
