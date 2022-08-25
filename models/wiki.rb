# wiki.rb

require 'splitter'

class Wiki < Splitter
  def advance(fat, open_titles)
    return [] unless @gens
    changes = []
    puts open_titles.size
    fat_first = fat[open_titles[0]]
    # puts fat_first.references.map(&:to_link).join(" - ")
    # puts fat_first.title
    linked = fat_first.tiddlers_linked
    puts linked.map(&:to_link).join(" - ")

    puts tiddlers.size
    marker = "RejectBelowHere"
    puts index = open_titles.index(marker)
    open_titles[index+1..-1].each do |title|
      changes << title
      delete(title)
    end

    puts tiddlers.size
    linked.each do |tiddler|
      title = tiddler.title
      unless self[title]
        hash = tiddler.to_h
        self[title] = Tiddler.new(self, title, hash)
        changes << hash
      end
    end
    puts tiddlers.size
    puts changes.size
    if changes.size > 0
      gen_step_last = self["GenSteps"].titles_linked[-1]
      gen_step = gen_step_last[-5..-1].to_i + 1
      gen_step = "GenStep" + '%05i' % gen_step
      puts gen_step
    end
    changes
  end
end
