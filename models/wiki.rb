# wiki.rb

require 'splitter'
require 'benchmark'

class Wiki < Splitter
  def advance_gen
    puts tiddlers.size
    open_tiddlers = self["DefaultTiddlers"].tiddlers_linked
    puts open_tiddlers.size
    marker = self["RejectBelowHere"]
    puts index = open_tiddlers.index(marker)
    open_tiddlers[index+1..-1].each { |t| delete(t.title) }
    puts tiddlers.size
    fat = Wiki.fat
    puts fat.tiddlers.size
    my_first = open_tiddlers[0]
    fat_first = fat[my_first.title]
    puts fat_first.references.map(&:title).join(" - ")
    puts my_first.title
    puts fat_first.titles_linked.join(" - ")
    write
    # `open #{new_name}`
  end

  Ref = Struct.new(:linker, :link)

  def Wiki.time_references
    f1, linking_tiddlers = nil
    timeb("fat") { f1 = fat }
    timeb("warm") { linking_tiddlers = f1.warm_references }
    timeb("refs") { f1.tiddlers[333...363].map(&:references) }
    [f1, linking_tiddlers]
  end

  def warm_references
    puts tiddlers.size
    full = normal_tiddlers.map do |t|
      t.tiddler_links.map { |link| Ref.new(t.title, link) }
    end.flatten
    puts full.size
    links = full.group_by &:link
    puts links.size
    linking_tiddlers = links.keys.group_by {|s| self.referent(s)}
    puts linking_tiddlers.size
    linking_tiddlers.each do |tiddler, refs|
      titles = refs.map{|r|links[r]}.flatten.map(&:linker).uniq.sort
      if tiddler
        tiddler.references = titles.map{ |title| self[title] }
      else
        puts titles.size
      end
    end
    linking_tiddlers
  end

  def show_scripts
    puts @mid.lines[-1]
    puts @after.lines[0..4]
  end

  def show_jq
    lines = @after.lines
    puts lines.size
    script_line = lines[1]
    puts script_line
  end
end
