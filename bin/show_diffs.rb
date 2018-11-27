# show_diffs.rb

require 'splitter'

name = "current"
titles = Splitter.fat.titles
dir = "#{mp? ? '/Volumes/SH1' : '/Users/rd'}/_backup"
Dir.chdir(dir)
names = Dir.glob("*.html").reverse
puts names.size
(0..21).each do |n|
  prev_name = names[n]
  prev_titles = Splitter.new("#{dir}/#{prev_name}").titles
  puts; puts name
  puts titles.size
  puts prev_titles.size if prev_titles.size != titles.size
  added = titles - prev_titles
  puts added.size if added.size > 0
  removed = prev_titles - titles
  number_removed = removed.size
  if number_removed > 0
    puts "**********************"
    puts number_removed
    puts removed
    puts "**********************"
  end
  name = prev_name
  titles = prev_titles
end
puts; puts name
