# changeset.rb

require 'splitter'

class Changeset
  attr_reader :tiddlers, :deleted

  def initialize(json)
    @tiddlers = []
    @deleted = []
    JSON.parse(json).each do |hash|
      (title = hash["title"]) ?
        @tiddlers << Tiddler.new(self, title, hash) :
        @deleted << hash
    end
  end

  def titles
    @tiddlers.map &:title
  end
end
