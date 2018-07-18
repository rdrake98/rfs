require 'roda'
require 'splitter'

$wikis = {
  "fat" => Splitter.fat,
  "dev" => Splitter.dev
}
puts $wikis["fat"].edition
puts $wikis["dev"].edition

class App < Roda
  route do |r|
    r.on "public" do
      r.post "change_tiddler" do
        p = r.params
        wiki_type = p['wiki']
        wiki = $wikis[wiki_type]
        if wiki
          message = "#{p['title']} #{p['action']} in #{wiki_type}"
          puts message
          wiki.add_changes(p['changes'])
          message
        else
          message = "#{p['title']} not #{p['action']} for #{wiki_type}"
          puts message
          message
        end
      end

      r.post "save" do
        p = r.params
        wiki_type = p['wiki']
        wiki = $wikis[wiki_type]
        if wiki
          puts "saving #{wiki_type}"
          wiki.save
          wiki.edition
        else
          puts "saving not supported for #{wiki_type}"
          ""
        end
      end
    end

    r.get "local" do
      puts $wikis[:fat]['rfs'].content
      "local only"
    end
  end
end
