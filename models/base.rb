# base.rb

require 'cgi'
require 'stringio'

def mp?; `hostname`[0..1] == "mp"; end
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

def snip(original_file)
  original_file = ENV["TM_FILEPATH"] || original_file || ENV["PWD"] + "/"
  original_file = ENV["PWD"] + "/" + original_file if original_file[0..0] != "/"
  file = original_file.sub("#{ENV['HOME']}/", "")
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
  File.write("/Users/rd/Dropbox/_shared/out#{Time.now_str('.%H%M%S')}.txt", out)
  puts out
end

def show(name, result, multi_line)
  puts "#{name}:#{multi_line ? "\n" : " "}#{result}"
end

def show_global(name, multi_line=nil)
  if multi_line
    puts name
    eval("puts #{name}")
  else
    result = eval(name)
    puts "#{name}: #{result}"
  end
end

def split(result, separator)
  result && result.split(separator).join("\n") || ""
end

def show_env(name, multi_line=nil)
  result = ENV[name]
  separator = multi_line && multi_line != :m && (multi_line == :c ? ":" : " ")
  result = split(result, separator) if separator
  show name, result, multi_line
end

def show_cmd(cmd, multi_line=nil)
  show cmd, `#{cmd}`, multi_line
end

class Object
  def in?(collection)
    collection.include?(self)
  end
end

class String
  def wikiize
    self[0..0].upcase + self[1..-1]
  end

  def link(url)
    "[[#{gsub("|",":").gsub("]]","))")}|#{url.gsub("]]","%5D%5D")}]]"
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
  def Time.now_str(suffix="")
    new.utc.strftime("%y%m%d#{suffix}")
  end

  def Time.fov_str(i=1, date_now=now_str)
    "FOv#{date_now}#{sprintf('%02i',i)}"
  end

  def to_minute(day_size=false)
    pattern = "%-d %b %y %H:%M"
    pattern.gsub!("-","") if day_size
    strftime pattern
  end
end
