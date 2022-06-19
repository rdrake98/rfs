# wiki.rb

require 'splitter'
require 'benchmark'

class Wiki < Splitter
  def Wiki.quicker_edition
    my_fat = nil
    timeb("slow") {puts (my_fat = fat).edition}
    timeb("quicker") {puts fat_edition}
    timeb("quickest") {puts my_fat.edition}
  end
end
