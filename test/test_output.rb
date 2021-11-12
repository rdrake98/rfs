# test_output.rb

require 'minitest/autorun'
require 'splitter'

class TestOutput < MiniTest::Test
  few = ARGV[0] == "few" || !ARGV[0]
  type = !few && ARGV[0] || "dev"
  wiki_path = Dir.data "#{type}_.html"
  path = Dir.data "#{type}_output.html"
  wiki = Splitter.new(wiki_path)
  limit = few && wiki["RubyTests"].tiddler_links.size
  puts limit
  one = ARGV[1]
  all = !few && !one
  re = /src=".*?"/
  re2 = /href="txmt:.*?"/
  last_name = "--"
  count = 0
  describe "all" do
    Regex.scan_output(path).each_with_index do |chunk, i|
      name, output = chunk
      if all || few && (i < limit || name =~ /RFF\d\d/) || one && name == one
        last_name = name
        count += 1
        it "output for '#{name}'" do
          output.gsub!(re, 'src="image/URL"')
          output.gsub!(re2, 'src="textmate/URL"')
          wiki_output = wiki[name].output.gsub(re, 'src="image/URL"')
          wiki_output.gsub!(re2, 'src="textmate/URL"')
          assert_equal(output, wiki_output)
        end
      end
    end
  end
  puts last_name if few
  puts count if few
  puts
  puts "ruby -e 'require \"Splitter\"; Splitter.#{type}[\"#{one}\"].output;' dd" if one
  puts
end
