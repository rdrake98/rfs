require 'roda'
require 'wiki_with_tabs'

class Wany < Roda
  puts "restarting wany.rb"
  puts ENV["RUBYLIB"]
  @@fat = nil

  def Wany.fat_
    if @@fat&.edition != (edition = Splitter.fat_edition)
      puts "", edition + " loading"
      timeb("load fat") { @@fat = Splitter.fat }
      timeb("cache elinks") { @@fat.tiddlers.each(&:external_links) }
    end
    @@fat
  end

  def fat_
    fat = Wany.fat_
    puts "", fat.edition + " being used"
    fat
  end

  Thread.new do
    loop do
      begin
        Wany.fat_
        sleep(20)
      end
    end
  end

  route do |r|
    r.get "show" do
      fat ? fat.tiddlers.size.to_s : "nil"
    end

    r.get "tabs" do
      timeb("total") { WikiWithTabs.new(fat_).show_final_tabs.to_s }
    end

    r.get "unpeel" do
      WikiWithTabs.unpeel
    end

    r.get "copy_tabs_to_fat" do
      WikiWithTabs.copy_to_fat(fat_)
      "copy_to_fat complete"
    end

    r.get "commit_tabs_mods" do
      WikiWithTabs.commit_mods
    end
  end
end
