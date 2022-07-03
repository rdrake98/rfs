# wiki.rb

require 'splitter'

class Wiki < Splitter
  def advance(fat)
    return "[]" unless @gens
    changes = []
    open_tiddlers = self["DefaultTiddlers"].tiddlers_linked
    puts open_tiddlers.size
    my_first = open_tiddlers[0]
    fat_first = fat[my_first.title]
    puts fat_first.references.map(&:title).join(" - ")
    puts my_first.title
    puts fat_first.titles_linked.join(" - ")
    puts tiddlers.size
    marker = self["RejectBelowHere"]
    puts index = open_tiddlers.index(marker)
    open_tiddlers[index+1..-1].each do |t|
      changes << t.title
      delete(t.title)
    end
    puts tiddlers.size
    JSON[changes]
  end
end
