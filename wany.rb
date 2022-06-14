require 'roda'
require 'wiki_with_tabs'

class Wany < Roda
  puts "restarting wany"
  puts ENV["RUBYLIB"]
  Fat = Wiki.fat
  puts Fat.tiddlers.size

  route do |r|
    r.get "show" do
      Fat.tiddlers.size.to_s
    end

    r.get "tabs" do
      timeb("total") { WikiWithTabs.new.show_final_tabs.to_s }
    end

    r.get "unpeel" do
      WikiWithTabs.unpeel
    end

    r.get "copy_tabs_to_fat" do
      WikiWithTabs.copy_to_fat
      "copy_to_fat complete"
    end

    r.get "commit_tabs_mods" do
      WikiWithTabs.commit_mods
    end
  end
end
