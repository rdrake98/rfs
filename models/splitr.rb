# splitr.rb

require 'splitter'
require 'dd' if $dd

class Splitr < Splitter
  def []=(title, tiddler)
    @tiddler_hash[title] = tiddler
    puts title unless tiddler
  end

  def self.show_history(n)
    Dir.chdir "/Volumes/SH1/fatword"
    dirs = Dir.glob "*"
    puts dirs.size
    Dir.chdir(dirs[n])
    puts Dir.pwd
    glob = Dir.glob "whiteword*.html"
    glob = Dir.glob "fatword*.html" if glob.size == 0
    puts glob.size
    (0...glob.size).step(100).map{|i| glob[i]}.each do |f|
      print f, " "
      w = Splitter.new(f);
      puts w.tiddlers.size
    end
    glob.size
  end
end
