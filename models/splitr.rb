# splitr.rb

require 'splitter'
require 'tidlr'
require 'dd' if $dd

class Splitr < Splitter
  def initialize(filename)
    @filename = filename
    @tiddler_hash = {}
    @tiddler_splits = {}
    @host = mp? ? "p" : "g"
    open(filename) do |file|
      @before = ""
      until (line = file.gets) =~ /<div id="storeArea">/
        @before << line
      end
      @before << line
      while (line = Tidlr.repair(file.gets)) =~ /<div title=.*/
        tiddler = Tidlr.from_file(self, file, line)
        self[tiddler.title] = tiddler
      end
      binding.pry if $dd
      @mid = line
      until (line = file.gets) =~ /^<script id="jsArea" type="text\/javascript">/
        @mid << line
      end
      @mid << line
      @code = ""
      until (line = file.gets) =~ /^<\/script>/
        @code << line
      end
      @after = line
      @after << line while (line = file.gets)
    end
  end

  def store_size
    unsorted_tiddlers.map(&:size).reduce(0, &:+)
  end

  def write(suffix="_")
    filename = new_name(suffix)
    puts "writing splitr to #{filename}"
    File.write(filename, contents)
    filename
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
