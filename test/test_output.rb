# test_output.rb

require 'minitest/autorun'
require 'splitter'

class TestOutput < MiniTest::Test
  few = ARGV[0] == "few"
  type = !few && ARGV[0] || "dev"
  wiki_path = "#{ENV['data']}/#{type}_.html"
  path = "#{ENV['data']}/#{type}_output.html"
  wiki = Splitter.new(wiki_path)
  limit = few && wiki["RubyTests"].tiddler_links.size
  one = ARGV[1]
  all = !few && !one
  describe "all" do
    Regex.scan_output(path).each_with_index do |chunk, i|
      name, output = chunk
      if all || few && (i < limit || name =~ /RFF\d\d/) || one && name == one
        it "output for '#{name}'" do
          assert_equal(output, wiki[name].output)
        end
      end
    end
  end
  puts
  puts "ruby -e 'require \"Splitter\"; Splitter.#{type}[\"#{one}\"].output;' dd" if one
  puts
end
