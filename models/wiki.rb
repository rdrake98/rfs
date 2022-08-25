# wiki.rb

require 'splitter'

class Wiki < Splitter
  def advance(fat, open_titles)
    return [] unless @gens
    puts open_titles.size
    advance_title = open_titles[0]
    fat_first = fat[advance_title]
    return [] unless fat_first
    # puts fat_first.references.map(&:to_link).join(" - ")
    # puts fat_first.title
    linked = fat_first.tiddlers_linked

    marker = "RejectBelowHere"
    index = open_titles.index(marker)
    changes = []
    open_titles[index+1..-1].each do |title|
      changes << title
      delete(title)
    end

    linked.each do |tiddler|
      title = tiddler.title
      unless self[title]
        hash = tiddler.to_h
        self[title] = Tiddler.new(self, title, hash)
        changes << hash
      end
    end
    puts changes.size
    if changes.size > 0
      gen_steps = self["GenSteps"]
      gen_step_last = gen_steps.titles_linked[-1]
      gen_step = gen_step_last[-5..-1].to_i + 1
      gen_step = "GenStep" + '%05i' % gen_step
      gen_steps.content += " - " + gen_step
      changes << gen_steps.to_h
      content = advance_title + "\n" + linked.map(&:to_link).join(" - ")
      changes << create_new(gen_step, content).to_h
    end
    changes
  end
end
