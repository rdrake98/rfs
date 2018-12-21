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

  def self.show_history(n=13, just_one=false, step=100)
    $last_save = Time.new(0)
    dirs = Dir.glob "/Volumes/SH1/fatword/*"
    range = just_one ? (n..n) : (n...dirs.size)
    range.each {|n| puts "", n; show_sample(dirs[n], step)}
    unless just_one && n < dirs.size
      puts "", dirs.size
      show_sample("/Volumes/SH1/_backup", step)
      puts "", range.size + 1
    end
  end

  def self.show_sample(dir, step)
    Dir.chdir(dir)
    puts dir
    glob = Dir.glob "whiteword*.html"
    glob = Dir.glob "f*.html" if glob.size == 0
    puts "#{glob.size} with step #{step}"
    (0...glob.size).step(step).map{|i| glob[i]}.each do |f|
      print f, " "
      begin
        w = new(f)
        save = w.save_time
        tiddler = w.tidder_time
        puts "#{w.tiddlers.size} - #{save.to_minute 2} - #{tiddler.to_minute 2}"
        puts "*** save before tiddler ***" if save < tiddler
        puts "*** save before last save ***" if save < $last_save
        $last_save = save
      rescue => e
        puts e
      end
    end
  end

  def save_time
    s = @filename.gsub(/\D/, "")
    s = "20" + s if s.size == 12
    Time.new(s[0..3],s[4..5],s[6..7],s[8..9],s[10..11],s[12..13])
  end

  def tidder_time
    tiddlers.map(&:modified).max
  end
end
