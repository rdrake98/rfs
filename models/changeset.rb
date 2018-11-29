# changeset.rb

require 'splitter'

class Changeset < Splitter
  attr_reader :deleted

  def from(json)
    @deleted = []
    add_tiddlers(json, false)
    self
  end

  def delete(title, noisy=false)
    @deleted << title
  end
end
