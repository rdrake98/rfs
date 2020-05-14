# show_tiddler.rb

require 'splitter'

def show tiddler
  puts tiddler.header
  puts tiddler.modifier
  puts tiddler.modified
  puts tiddler.changecount
  puts
end

splitter = Splitter.dev !ARGV[1]
tiddler = splitter[ARGV[0] || "DefaultTiddlers"]
show tiddler
tiddler.content = "bleh"
show tiddler
puts tiddler.changed?
