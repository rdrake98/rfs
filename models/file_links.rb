# file_links.rb
# as the next line suggests these are all external links
require 'external_link'

class FileLinks
  attr_accessor :name, :lines
  def initialize(window, name)
    @name = name
    @lines = window["tabs"].map {|tab| ExternalLink.new(tab)}
  end

  def purge
    @lines.select!(&:wanted)
  end

  def content
    @lines.collect(&:content).join
  end
end
