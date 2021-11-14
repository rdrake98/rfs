# bin/quick_fat.rb

require 'splitter'

$fixes = 0
$ex = nil
preamble = ARGV[0] ? "../#{ARGV[0]}/" : ""
wiki = Splitter.new(Dir.data("#{preamble}fat_.html"))
size = wiki.tiddlers.size
puts "#{size} tiddlers"
scan = Regex.scan_output(Dir.data("#{preamble}fat_output.html"))
unless scan.size == size
  puts "#{scan.size} javascript tiddlers - exiting"
  exit 1
end
count = 0
failures = scan.map do |name, output|
  js_output, ruby_output = wiki[name].fix_outputs(output)
  if js_output == ruby_output
    count += 1
    nil
  else
    name
  end
end.compact
size = wiki.testing_tiddlers.size
puts "#{size} tiddlers compared"
percent = count.to_f/size*100
puts "#{"%.1f" % (percent)}% passing - #{count}"
count = size - count
percent = 100 - percent
puts "#{"%.1f" % (percent)}% failing - #{count}"
failures = failures - wiki.titles_excluded
puts "*** #{failures.size} failures ***" if failures.size != count
# exit if failures.size == 0
puts
p failures if failures.size < 100
puts
# puts "ruby test/test_output.rb fat #{failures.sample}"
puts "#{$fixes} fixes"
puts $ex
