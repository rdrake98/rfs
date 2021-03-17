# test_splits.rb

require 'minitest/autorun'
require 'splitter'

patches = <<~SH
TextMate
BBC 2
iPhone
Mc*

SH
(Wiki = Splitter.new).create_new("NamePatches", patches, "Name Patches")

module Minitest::Assertions
  def assert_split(output, name)
    assert_equal(output, Wiki.splitNameFromPatches(name))
  end
end

class TestSplits < MiniTest::Test
  describe "normal" do
    it "basics" do
      assert_split("New Name", "NewName")
      assert_split("Three Word Name", "ThreeWordName")
    end
    it "too short" do
      assert_split("LeoFu", "LeoFu")
    end
    it "capitals" do
      assert_split("EPA Head", "EPAHead")
      assert_split("What IBM Wants", "WhatIBMWants")
      assert_split("Learning XP", "LearningXP")
    end
    it "Irish" do
      assert_split("Sean O'Casey", "SeanOCasey")
      assert_split("O'Connor", "OConnor")
    end
  end
  describe "patched" do
    it "basics" do
      assert_split("TextMate", "TextMate")
      assert_split("BBC 2", "BBC2")
    end
    it "words around" do
      assert_split("TextMate Notes", "TextMateNotes")
      assert_split("Learning TextMate", "LearningTextMate")
      assert_split("Taking TextMate Notes", "TakingTextMateNotes")
      assert_split("Watching BBC 2", "WatchingBBC2")
      assert_split("Watching BBC 2 Newsnight", "WatchingBBC2Newsnight")
    end
    it "lower first" do
      assert_split("iPhone", "IPhone")
      assert_split("My iPhone", "MyIPhone")
      assert_split("iPhone Release", "IPhoneRelease")
    end
    it "Scottish" do
      assert_split("McTavish", "McTavish")
      assert_split("Jock McTavish", "JockMcTavish")
    end
  end
end
