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
        line1 = line.scrub('£')
        line2 = line.scrub
        binding.pry if $dd
        line = line2
        ending = line =~ /<\/div>/
      end
    end until ending
    begin
      div_text << line
    rescue
      line1 = line.scrub('£')
      line2 = line.scrub
      binding.pry if $dd
      line = line2
      div_text << line
    end
  end

  def splitdown
    (splitname || @title).downcase
  end
end
