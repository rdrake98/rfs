# base.rb

require 'time'
require 'cgi'
require 'stringio'

def mp?; `hostname`[0..1] == "mp"; end
def hostc; mp? ? "p" : "g"; end
def jem?; Dir.pwd != "/Users/rd/rf/rfs"; end

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
  File.write("/Users/rd/Dropbox/_shared/out#{Time.now_dotted}.txt", out)
  puts out
end

class Object
  def in?(collection); collection.include?(self); end

  def taps; tap{|s| puts s}; end
end

class String
  def link(url)
    text = gsub("|",":").gsub("]]","))").gsub("\u00A0", " ") # nbsp
    "[[#{text}|#{url.gsub("]]","%5D%5D")}]]"
  end

  def strip_semi
    stripped = rstrip
    if stripped =~ /^(.*);\s+(\/\/.*)$/
      stripped = $1 + " " + $2
    elsif stripped[-1] == ";"
      stripped = stripped[0..-2]
      stripped.rstrip!
    end
    stripped += "\n"
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
    def glob(*args)
      original_glob(*args).sort
    end

    alias :original_chdir :chdir
    def chdir(*args)
      args[0].class == Symbol ?
        original_chdir(ENV[args[0].to_s]) :
        original_chdir(*args)
    end

    def method_missing(name, *args)
      args.size == 0 ?
        ENV[name.to_s] || super.method_missing(name) :
        super.method_missing(name, *args)
    end
  end
end

def snip(original_file)
  original_file = ENV["TM_FILEPATH"] || original_file || ENV["PWD"] + "/"
  original_file = ENV["PWD"] + "/" + original_file if original_file[0..0] != "/"
  file = original_file.sub("#{Dir.home}/", "")
  code = file == "ww/dev/code/compiled/code.js"
  isDir = file[-1..-1] == "/"
  isMine = file != original_file
  require_relative "/Users/rd/scripts/textmate/base_tm"
  selection = TMSelection.new
  text = selection.text
  line = selection.line
  url_end = line < 10 ? "" : "&line=#{line}"
  prefix = isMine ? "../" : ""

  bits = file.split('/')
  if isDir then
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
