# splitr.rb

require 'splitter'
require 'tidlr'

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

  def self.write_history(n=13, just_one=false, step=100, writing=false)
    mkdir
    dirs = Dir.glob "/Volumes/SH1/fatword/*"
    range = just_one ? (n..n) : (n...dirs.size)
    range.each {|n| puts "", n; write_sample(dirs[n], step, writing)}
    unless just_one && n < dirs.size
      puts "", dirs.size
      write_sample("/Volumes/SH1/_backup", step, writing)
      puts "", range.size + 1
    end
  end

  def self.dir; "/Users/rd/rf/tiddlers3"; end

  def write_tiddlers(time=nil, noisy=true, message=edition)
    # byebug if $dd
    dir = Dir.pwd
    Dir.chdir(Splitr.dir)
    FileUtils.rm Dir.glob('*.txt')
    puts "writing #{message}" if noisy
    tiddlers.each(&:write)
    puts "committing #{message}" if noisy
    if time
      git_time = time.to_s[0..-7]
      pre = "git add .; GIT_COMMITTER_DATE="
      `#{pre}"#{git_time}" git commit -m #{message} --date "#{git_time}"`
    else
      `gcaa #{message}`
    end
    Dir.chdir(dir)
  end

  def self.write_sample(dir, step=1, writing=false, start_string=nil)
    $last_save ||= Time.new(0)
    Dir.chdir(dir)
    puts dir
    glob = Dir.glob "whiteword*.html"
    glob = Dir.glob "f*.html" if glob.size == 0
    start = (start_string && glob.index {|f| f[start_string]}) || 0
    puts "#{glob.size} starting at #{start} with step #{step}"
    (start...glob.size).step(step).map{|i| glob[i]}.each do |f|
      print f, " "
      begin
        w = new(f)
        save = w.save_time
        tiddler = w.tidder_time
        puts "#{w.tiddlers.size} - #{save.to_minute 2} - #{tiddler.to_minute 2}"
        puts "*** save before tiddler ***" if save < tiddler
        puts "*** save before last save ***" if save < $last_save
        w.write_tiddlers(save, false) if writing
        $last_save = save
      rescue => e
        puts e
        Dir.chdir(dir)
      end
    end
  end

  def self.mkdir(dir1=dir)
    FileUtils.remove_dir(dir1) if Dir.exist?(dir1)
    Dir.mkdir(dir1)
    Dir.chdir(dir1)
    `gin`
  end

  def self.test_write
    mkdir
    write_sample('/Users/rd/rf/_history/_backup', 1, true)
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
