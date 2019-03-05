# quick_fat.rb

require 'splitter'

wiki_path = "#{ENV['data']}/fat_.html"
path = "#{ENV['data']}/fat_output.html"
if ARGV[0]&.downcase == "c"
  if ARGV[0] == "c" && File.read(wiki_path) == File.read(ENV["fat"])
    puts "#{wiki_path} is up to date"
  else
    puts "#{Splitter.fat.tiddlers.size} tiddlers in current fat"
    puts "please seed from javascript"
    exit
  end
end
wiki = Splitter.new(wiki_path)
size = wiki.tiddlers.size
puts "#{size} tiddlers"
scan = Regex.scan_output(path)
unless scan.size == size
  puts "#{scan.size} javascript tiddlers - exiting"
  exit 1
end
count = 0
scan.each do |name, output|
  count += 1 if wiki[name].output == output
end
size = wiki.testing_tiddlers.size
puts "#{size} tiddlers compared"
percent = count.to_f/size*100
puts "#{"%.1f" % (percent)}% passing - #{count}"
count = size - count
percent = 100 - percent
puts "#{"%.1f" % (percent)}% failing - #{count}"
