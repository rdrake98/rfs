# base.rb

require 'time'
require 'cgi'
require 'stringio'
require 'benchmark'

Downloads = Dir.home + "/Downloads"

def mp?; `hostname`[0..1] == "mp"; end
def hostc; mp? ? "p" : "g"; end

def set_args(args)
  old_args = ARGV.clone
  while ARGV.size > 0; ARGV.shift; end
  args.each {|arg| ARGV << arg}
  old_args
end

def run(command)
  tokens = command.split /\s/
  args = set_args(tokens[1..-1])
  require_relative "test/#{tokens[0]}"
  set_args(args)
end

def runl(command)
  tokens = command.split /\s/
  args = set_args(tokens[1..-1])
  load "bin/#{tokens[0]}.rb"
  set_args(args)
end

module CGI::Util
  def h_n(string, regex); string.gsub(regex, TABLE_FOR_ESCAPE_HTML__); end
  def h2(string); h_n(string, /[&\"<>]/); end # don't escape single quotes
  def h3(string); h_n(string, /[&<>]/); end
  def h4(string); h_n(string, /[&\"]/); end
end

def capture_stdout
  old_stdout, $stdout = $stdout, StringIO.new
  yield
  $stdout.string
rescue
  return $stdout.string
ensure
  $stdout = old_stdout
end

def share_output(&block)
  out = capture_stdout(&block)
  File.write("#{Dir.home}/Dropbox/_shared/out#{Time.now_dotted}.txt", out)
  puts out
end

def timeb(label="", &block)
  result = nil
  seconds = Benchmark.realtime { result = block.call }
  puts '%-15s%.3f' % [label, seconds]
  result
end

class Object
  def in?(collection); collection.include?(self); end

  def true?; to_s.downcase == "true"; end

  def taps; tap{|s| puts s}; end
end

class String
  def link(url)
    text = gsub("|",":").gsub("]]","))").gsub("\u00A0", " ") # nbsp
    "[[#{text}|#{url.gsub("]]","%5D%5D")}]]"
  end
end

class Array
  def join_n
    size == 0 ? "" : join("\n") + "\n"
  end
end

class Time
  def Time.now_dotted; new.utc.dotted; end

  def dotted; strftime "%y%m%d.%H%M%S"; end

  def ymd; strftime "%y%m%d"; end

  def to_minute(long_day=false)
    strftime "%#{long_day ? '' : '-'}d %b %y %H:%M"
  end
end

class Dir
  class << self
    alias :original_glob :glob
    def glob(*args, **hash)
      original_glob(*args, **hash).sort
    end

    def cd(dir, subdir=nil)
      dir = dir.is_a?(Symbol) && ENV[dir.to_s] || dir
      chdir("#{dir}#{subdir && '/' + subdir}") == 0 ? self : nil
    end

    def method_missing(name, *args)
      (dir = ENV[name.to_s]) ?
        ([dir] + args).join("/") :
        super.method_missing(name, *args)
    end
  end
end

def snip(original_file)
  original_file = ENV["TM_FILEPATH"] || original_file || ENV["PWD"] + "/"
  original_file = ENV["PWD"] + "/" + original_file if original_file[0..0] != "/"
  code = original_file == Dir.compiled("code.js")
  file = original_file.sub("#{Dir.home}/", "")
  prefix = file != original_file ? "../" : ""
  require_relative "#{Dir.home}/scripts/textmate/base_tm"
  selection = TMSelection.new
  text = selection.text
  line = selection.line
  url_end = line < 10 ? "" : "&line=#{line}"

  bits = file.split('/')
  if file[-1] == "/" then
    puts bits[-1].link("#{prefix}#{file[0..-2]}")
  else
    fileURL = "txmt://open?url=file://#{file}#{url_end}"
    if code
      puts "[[compiled/code.js]] " + "line #{line}".link(fileURL)
    else
      dirLink = bits[-2] ?
        bits[-2].link("#{prefix}#{bits[0..-2].join('/')}") + "/" :
        ""
      fileURL = "#{prefix}#{file}" if ARGV[1]
      puts dirLink + bits.last.link(fileURL)
    end
    if text
      puts "{{{"
      puts text
      puts "}}}"
    end
  end
end
