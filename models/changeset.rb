# changeset.rb

require 'splitter'

class Changeset < Splitter
  attr_reader :deleted

  def initialize(json)
    super(nil)
    @deleted = []
    add_tiddlers(json, false)
  end

  def delete(title, noisy=false)
    @deleted << title
  end
end
