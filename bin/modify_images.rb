# modify_images.rb

require 'splitter'

splitter = Splitter.fat
tiddlers = splitter.tiddlers
tiddlers.each do |tiddler|
  tiddler.content = tiddler.content.gsub(
    /<html><img width="610" src="(.*)"><\/html>/,
    '[img[\1 ]]'
  )
end
changed = tiddlers.select(&:changed?)
puts changed.map(&:title)
puts tiddlers.size
puts changed.size
splitter.write
