# file_links.rb
# as the next line suggests these are all external links
require 'external_link'

class FileLinks
  attr_accessor :id, :name, :lines
  def initialize(window, name)
    @id = window["id"]
    @name = name
    @lines = window["tabs"].map {|tab| ExternalLinkSB.new(tab)}
  end

  def write
  end

  def purge
    @lines = @lines.select(&:wanted)
  end
end
