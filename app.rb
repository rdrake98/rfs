require 'roda'
require 'splitter'

$wikis = {"fat" => Splitter.fat, "dev" => Splitter.dev}
puts $wikis["fat"].edition
puts $wikis["dev"].edition

class App < Roda
  route do |r|
    r.on "public" do
      r.post "change_tiddler" do
        p = r.params
        wiki_type = p['wiki']
        wiki = $wikis[wiki_type]
        message = "#{p['title']} #{p['action']} in #{wiki_type}"
        puts message
        wiki.add_changes(p['changes']) if wiki
        message
      end

      r.post "save" do
        p = r.params
        wiki_type = p['wiki']
        wiki = $wikis[wiki_type] || Splitter.new(wiki_type)
        puts "saving #{wiki_type}"
        wiki.save(p['changes'])
      end
    end

    r.get "local" do
      puts $wikis["fat"]['rfs'].content
      "local only"
    end
  end
end
