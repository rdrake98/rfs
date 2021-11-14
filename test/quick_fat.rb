# quick_fat.rb

require 'splitter'

wiki_path = Dir.data "fat_.html"
path = Dir.data "fat_output.html"
wiki = Splitter.new(wiki_path)
size = wiki.tiddlers.size
puts "#{size} tiddlers"
scan = Regex.scan_output(path)
unless scan.size == size
  puts "#{scan.size} javascript tiddlers - exiting"
  exit 1
end
count = 0
failures = scan.map do |name, output|
  if output == wiki[name].output
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
exit if failures.size == 0
puts
p failures if failures.size < 100
puts
puts "ruby test/test_output.rb fat #{failures.sample}"
puts
