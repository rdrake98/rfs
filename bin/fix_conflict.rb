# fix_conflict.rb

require 'splitter'

fatword1 = Splitter.new Dir.home + "/Dropbox/fatword1.html"
fat = Splitter.fat
fatword1["DefaultTiddlers"].titles_linked.each do |title|
  puts title
  fat.update_from(fatword1, title)
end
fat.write
# fat.commit_mods
