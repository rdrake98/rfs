# changeset.rb

require 'splitter'

class Changeset < Splitter
  attr_reader :deleted

  def initialize
    super
    @deleted = []
  end

  def delete(title, noisy=false)
    @deleted << title
  end
end
