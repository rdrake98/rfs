# tidlr.rb

require 'tiddler'

# line2 = line.scrub {|c| c == "\xB0" ? "**" : "£"}
# \xB0 °
# \xA3 £
# \xAB -
# \xF1 ñ

class Tidlr < Tiddler
  def self.div_text(file, line)
    div_text = ""
    begin
      div_text << line
      line = file.gets
      begin
        ending = line =~ /<\/div>/
      rescue
        line2 = line.scrub do |c|
          c == "\xB0" ? "°" :
          (c == "\xA3" ? "£" :
          (c == "\xAB" ? "-" :
          (c == "\xF1" ? "ñ" :
          "??")))
        end
        binding.pry if $dd
        line = line2
        ending = line =~ /<\/div>/
      end
    end until ending
    begin
      div_text << line
    rescue
      binding.pry if $dd
      div_text << line.scrub
    end
  end

  def splitdown
    (splitname || @title).downcase
  end
end
