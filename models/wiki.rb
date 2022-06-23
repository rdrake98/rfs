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
    write
    `open #{new_name}`
    # fat = Wiki.fat
    # puts fat.tiddlers.size
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
