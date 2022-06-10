# read_filerd.rb

require 'splitter'

# dir = $dir || ARGV[0] || "rd"
$fat = Splitter.fat
tiddlers = $fat.tiddlers
puts tiddlers.size
$focus = tiddlers.select {|t| t.content.index("file:///Users/rd/")}
$focus += tiddlers.select {|t| t.content.index("file:///Users/richarddrake/")}
puts $focus.size
$focus.uniq!
puts $focus.size
re = /file:\/\/\/Users\/(rd|richarddrake)\/(.*?)(\]\]|\s)/
struct = Struct.new(:title, :rd, :sequel, :ending)
$structs = $focus.map do |t|
  t.content.scan(re).map do
    struct.new(t.title, $1, $2, $3)
  end
end.flatten
puts $structs.size
$structs[0..6].each {|x| puts "#{x.title} --- #{x.sequel}"}
$sequels = $structs.map(&:sequel).uniq.sort
puts $sequels.size
puts $sequels
