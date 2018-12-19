# splitr.rb

require 'splitter'
require 'dd' if $dd

class Splitr < Splitter
  def []=(title, tiddler)
    @tiddler_hash[title] = tiddler
    puts title unless tiddler
  end

  def self.show_history(n=nil)
    dirs = Dir.glob "/Volumes/SH1/fatword/*"
    range = n ? (n..n) : (13...dirs.size)
    range.each {|n| show_sample(dirs[n])}
    show_sample("/Volumes/SH1/_backup") unless n
    puts "", n ? 1 : range.size + 1
  end

  def self.show_sample(dir)
    Dir.chdir(dir)
    puts "", dir
    glob = Dir.glob "whiteword*.html"
    glob = Dir.glob "f*.html" if glob.size == 0
    puts glob.size
    (0...glob.size).step(100).map{|i| glob[i]}.each do |f|
      print f, " "
      begin
        w = new(f)
        puts w.tiddlers.size
      rescue => e
        puts e
      end
    end
  end
end
