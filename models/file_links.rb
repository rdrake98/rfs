# file_links.rb
# as the next line suggests these are all external links
require 'external_link'

class FileLinksSB
  attr_accessor :id, :name, :lines
  def initialize(window, name)
    @id = window["id"]
    @name = name
     @lines = window["tabs"].map {|tab| ExternalLinkSB.new(tab)}
  end

  def write
  end

  def purge
    @lines = wanted_lines
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
