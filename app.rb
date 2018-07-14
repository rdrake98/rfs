require 'roda'
require 'splitter'

$wikis = {
  fat: Splitter.fat,
  dev: Splitter.dev
}
puts $wikis[:fat].edition
puts $wikis[:dev].edition

class App < Roda
  route do |r|
    r.on "public" do
      r.post "change_tiddler" do
        p = r.params
        wiki_name = p['wiki'].to_sym
        message = "#{p['title']} #{p['action']} in #{wiki_name}"
        puts message
        wiki = $wikis[wiki_name]
        wiki.add_changes(p['changes'])
        message
      end
    end

    r.get "local" do
      puts $fat['MainMenu'].content
      "local only"
    end
  end
end
