# tidlr.rb

require 'tiddler'

class Tidlr < Tiddler
  def self.div_text(file, line)
    div_text = ""
    begin
      div_text << line
      line = file.gets
      begin
        ending = line =~ /<\/div>/
      rescue
        puts line
        puts line.scrub
        # binding.pry if $dd
        ending = true
      end
    end until ending
    div_text << line
  end

  def splitdown
    (splitname || @title).downcase
  end
end
