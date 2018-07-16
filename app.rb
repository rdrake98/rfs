require 'roda'
require 'splitter'
# require 'dd'

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
        wiki_type = p['wiki'].to_sym
        message = "#{p['title']} #{p['action']} in #{wiki_type}"
        puts message
        $wikis[wiki_type]&.add_changes(p['changes'])
        message
      end

      r.post "save" do
        p = r.params
        wiki_type = p['wiki'].to_sym
        puts "saving #{wiki_type}"
        $wikis[wiki_type]&.save
        "#{wiki_type} saved"
      end
    end

    r.get "local" do
      puts $wikis[:fat]['rfs'].content
      "local only"
    end
  end
end
