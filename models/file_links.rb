# file_links.rb
# as the next line suggests these are all external links
require 'external_link'

class ContentLinks
  attr_accessor :lines
  def initialize(content)
    @lines = content.lines.map { |line| ExternalLink.new(line) } # in
  end

  def urls
    @lines.select(&:wanted).map &:url
  end

  def content
    @lines.select(&:wanted).collect(&:content).join
  end
end

class FileLinks < ContentLinks
  attr_reader :filename
  attr_accessor :type, :number
  def initialize(filename, variant)
    @filename = filename
    @new_format = variant == :new_format
    @two_level = !@new_format && variant
    @type = @two_level ?
      @filename.split('/')[-2][0].upcase :
      (@filename.split('/')[-1][2] == "v" ? "V" : "N")
    @number = "00"
    super(File.read(filename))
  end

  def write
    File.write(@filename, content) # out
  end

  def month_or_day
    @filename.split('/')[@two_level ? -3 : -2][1..(@new_format ? 6 : 4)]
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
