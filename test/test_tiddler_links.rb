# test_tiddler_links.rb

require 'minitest/autorun'
require 'splitter'

class TestTiddlerLinks < MiniTest::Test

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
end
