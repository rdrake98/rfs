# changeset.rb

require 'splitter'

class Changeset < Splitter
  attr_reader :deleted

  def initialize(json)
    super(nil)
    @deleted = []
    add_tiddlers(json)
  end

  def add_tiddlers(json)
    JSON.parse(json).each do |hash|
      (title = hash["title"]) ?
        self[title] = Tiddler.new(self, title, hash) :
        @deleted << hash
    end
  end
end
