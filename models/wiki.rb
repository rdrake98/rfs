# wiki.rb

require 'splitter'
require 'benchmark'

class Wiki < Splitter
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
