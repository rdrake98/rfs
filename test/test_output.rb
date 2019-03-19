# test_output.rb

require 'minitest/autorun'
require 'splitter'

class TestOutput < MiniTest::Test
  few = ARGV[0] == "few"
  type = !few && ARGV[0] || "dev"
  wiki_path = "#{ENV['data']}/#{type}_.html"
  path = "#{ENV['data']}/#{type}_output.html"
  wiki = Splitter.new(wiki_path)
  limit = few ? wiki["RubyTests"].tiddler_links.size - 1 : ARGV[1].to_i - 1
  target = ARGV[1] if ARGV[1] && ARGV[1].to_i == 0
  describe "all" do
    Regex.scan_output(path)[0..limit].each do |name, output|
      unless target && name != target
        it "output for '#{name}'" do
          assert_equal(output, wiki[name].output)
        end
      end
    end
  end
  puts
  puts "ruby -e 'require \"Splitter\"; Splitter.#{type}[\"#{target}\"].output;' dd" if target
  puts
end
