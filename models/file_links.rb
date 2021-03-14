# file_links.rb
# as the next line suggests these are all external links
require 'external_link'

class ContentLinks
  attr_accessor :lines
  def initialize(content)
    @lines = content.lines.map { |line| ExternalLinkLine.new(line) } # in
  end

  def wanted_lines
    @lines.select(&:wanted)
  end

  def urls
    wanted_lines.map &:url
  end

  def content
    wanted_lines.collect(&:content).join
  end
end

class FileLinks < ContentLinks
  attr_reader :filename
  attr_accessor :type, :number
  def initialize(filename)
    @filename = filename
    @type = @filename.split('/')[-1][2] == "v" ? "V" : "N"
    @number = "00"
    super(File.read(filename))
  end

  def write
    File.write(@filename, content) # out
  end

  def month_or_day
    @filename.split('/')[-2][1..4]
  end

  def machine
    "m#{@filename.split('/')[-1][1]}"
  end

  def group
    "F#{month_or_day}#{machine}#{type}"
  end

  def tiddler_name
    "#{group}#{number}"
  end
end

class FileLinksSB < ContentLinks
  attr_accessor :id, :name
  def initialize(window, name)
    @name = name
    @id = window["id"]
    @lines = window["tabs"].map {|tab| ExternalLinkSB.new(tab)}
  end

  def write
  end

  def purge
    @lines = wanted_lines
  end
end
