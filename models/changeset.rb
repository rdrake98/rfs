# changeset.rb

require 'tiddler'
require 'json'

class Changeset
  attr_reader :tiddlers, :deleted

  def initialize(json)
    @tiddlers = []
    @deleted = []
    JSON.parse(json).each do |hash|
      (title = hash["title"]) ?
        unless title == "Search"
          @tiddlers << Tiddler.new(self, title, hash)
        end :
        @deleted << hash
    end
  end

  def titles
    @tiddlers.map &:title
  end
end
