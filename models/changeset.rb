# changeset.rb

require 'splitter'

class Changeset
  attr_reader :tiddlers, :deleted

  def initialize(json)
    @tiddlers = []
    @deleted = []
    JSON.parse(json).each do |hash|
      (title = hash["title"]) ?
        if title != "Search"
          @tiddlers << Tiddler.new(self, title, hash)
        end :
        @deleted << hash
    end
  end

  def titles
    @tiddlers.map &:title
  end
end
