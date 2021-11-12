# test_output.rb

require 'minitest/autorun'
require 'splitter'

class TestOutput < MiniTest::Test
  few = ARGV[0] == "few" || !ARGV[0]
  type = !few && ARGV[0] || "dev"
  wiki_path = Dir.data "#{type}_.html"
  path = Dir.data "#{type}_output.html"
  wiki = Splitter.new(wiki_path)
  one = ARGV[1]
  all = !few && !one
  describe "all" do
    Regex.scan_output(path).each_with_index do |chunk, i|
      name, output = chunk
      # 95 seems to be number of tests in RubyTests
      if all || few && (i < 95 || name =~ /RFF\d\d/) || one && name == one
        it "output for '#{name}'" do
          js_output, ruby_output = wiki[name].fix_outputs(output)
          assert_equal(js_output, ruby_output)
        end
      end
    end
  end
  puts "ruby -e 'require \"Splitter\"; Splitter.#{type}[\"#{one}\"].output;' dd" if one
end
