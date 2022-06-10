# read_filerd.rb

require 'splitter'

dir = $dir || ARGV[0] || "rd"
$fat = Splitter.fat
tiddlers = $fat.tiddlers
puts tiddlers.size
$focus = tiddlers.select {|t| t.content.index("file:///Users/#{dir}/")}
puts $focus.size
re = /file:\/\/\/Users\/#{dir}\/(.*?)(\]\]|\s)/
xx = Struct.new(:title, :sequel)
$sequels = $focus.map{|t|
  t.content.scan(re).map do
    xx.new(t.title, $1)
  end
}.flatten
puts $sequels.size
$sequels.each {|x| puts "#{x.title} --- #{x.sequel}"}
